defmodule Bundlex.Toolchain.VisualStudio do
  @moduledoc false
  # Toolchain definition for Microsoft Visual Studio.
  #
  # It tries to determine Visual Studio root directory before compolation starts
  # and set up native.appropriate environment variables that will cause using right
  # compiler for given platform by calling vcvarsall.bat script shipped with
  # Visual Studio.
  #
  # Visual Studio directory may be override by setting VISUAL_STUDIO_ROOT
  # environment variable.

  use Bundlex.Toolchain

  alias Bundlex.Helper.{GitHelper, PathHelper}
  alias Bundlex.Native
  alias Bundlex.Output

  @impl true
  def before_all!(:windows32) do
    [run_vcvarsall("x86")]
  end

  @impl true
  def before_all!(:windows64) do
    [run_vcvarsall("amd64")]
  end

  @impl true
  def compiler_commands(%Native{interface: interface} = native) do
    # TODO escape quotes properly

    includes_part =
      Enum.map_join(native.includes, " ", fn include ->
        ~s(/I "#{PathHelper.fix_slashes(include)}")
      end)

    sources_part =
      Enum.map_join(native.sources, " ", fn source -> ~s("#{PathHelper.fix_slashes(source)}") end)

    if not (native.libs |> Enum.empty?()) and not GitHelper.lfs_present?() do
      Output.raise(
        "Git LFS is not installed, being necessary for downloading windows *.lib files for dlls #{inspect(native.libs)}. Install from https://git-lfs.github.com/."
      )
    end

    libs_part = Enum.join(native.libs, " ")

    unquoted_dir_part =
      native.app
      |> Toolchain.output_path(interface)
      |> PathHelper.fix_slashes()

    dir_part = ~s("#{unquoted_dir_part}")

    common_options = "/nologo"
    compile_options = "#{common_options} /EHsc /D__WIN32__ /D_WINDOWS /DWIN32 /O2 /c"
    link_options = "#{common_options} /INCREMENTAL:NO /FORCE"

    output_path = Toolchain.output_path(native.app, native.name, interface)

    deps =
      native.deps
      |> Enum.map(&(Toolchain.output_path(&1.app, &1.name, &1.interface) <> ".lib"))
      |> paths()

    commands =
      case native do
        %Native{type: :native, interface: :nif} ->
          [
            "(cl #{compile_options} #{includes_part} #{sources_part})",
            ~s[(link #{link_options} #{libs_part} /DLL /OUT:"#{PathHelper.fix_slashes(output_path)}.dll" *.obj #{deps})]
          ]

        %Native{type: :lib} ->
          [
            "(cl #{compile_options} #{includes_part} #{sources_part})",
            ~s[(lib /OUT:"#{PathHelper.fix_slashes(output_path)}.lib" *.obj #{deps})]
          ]

        %Native{type: type, interface: :nif} when type in [:cnode, :port] ->
          [
            "(cl #{compile_options} #{includes_part} #{sources_part})",
            ~s[(link /libpath:"#{:code.root_dir() |> Path.join("lib/erl_interface-5.5.2/lib") |> PathHelper.fix_slashes()}" #{link_options} #{libs_part} /OUT:"#{PathHelper.fix_slashes(output_path)}.exe" *.obj #{deps})]
          ]
      end

    [
      "(if not exist #{dir_part} mkdir #{dir_part})",
      "(pushd #{dir_part})",
      commands,
      "(popd)"
    ]
    |> List.flatten()
  end

  # Runs vcvarsall.bat script
  defp run_vcvarsall(vcvarsall_arg) do
    program_files = System.fetch_env!("ProgramFiles(x86)") |> Path.expand()
    directory_root = Path.join([program_files, "Microsoft Visual Studio"])

    vcvarsall_path =
      directory_root
      |> build_vcvarsall_path()

    case File.exists?(vcvarsall_path) do
      false ->
        Output.raise(
          "Unable to find vcvarsall.bat script within Visual Studio root directory. Is your Visual Studio installation valid? (and file is in VC directory?)"
        )

      true ->
        ~s/(if not defined VCINSTALLDIR call "#{vcvarsall_path}" #{vcvarsall_arg})/
    end
  end

  defp build_vcvarsall_path(root) do
    vswhere = Path.join([root, "Installer", "vswhere.exe"])
    vswhere_args = ["-property", "installationPath", "-latest"]

    with true <- File.exists?(vswhere),
         {maybe_installation_path, 0} <- System.cmd(vswhere, vswhere_args) do
      installation_path = String.trim(maybe_installation_path)

      Path.join([installation_path, "VC", "Auxiliary", "Build", "vcvarsall.bat"])
      |> PathHelper.fix_slashes()
    else
      false ->
        Output.raise(
          "Unable to find vswhere.exe at #{vswhere}. Is Visual Studio installed correctly?"
        )

      {_output, return_value} ->
        Output.raise(
          "vswhere.exe failed with status #{return_value}. Unable to locate Visual Studio installation."
        )
    end
  end

  defp paths(paths, flag \\ "") do
    Enum.map_join(paths, " ", fn p -> "#{flag}#{path(p)}" end)
  end

  defp path(path) do
    path = path |> String.replace(~S("), ~S(\")) |> Path.expand()
    ~s("#{path}")
  end
end
