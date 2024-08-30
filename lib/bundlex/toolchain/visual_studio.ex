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

  # TODO: These should also include the ability to set the target architecture.
  @impl true
  def before_all!(:windows32) do
    [run_vcvarsall("x86")]
  end

  @impl true
  def before_all!(:windows64) do
    [run_vcvarsall("amd64")]
  end

  @impl true
  def compiler_commands(%Native{interface: :nif} = native) do
    # TODO escape quotes properly

    includes_part =
      Enum.map_join(native.includes, " ", fn include ->
        "/I \"#{PathHelper.fix_slashes(include)}\""
      end)

    sources_part =
      Enum.map_join(native.sources, " ", fn source -> "\"#{PathHelper.fix_slashes(source)}\"" end)

    if not (native.libs |> Enum.empty?()) and not GitHelper.lfs_present?() do
      Output.raise(
        "Git LFS is not installed, being necessary for downloading windows *.lib files for dlls #{inspect(native.libs)}. Install from https://git-lfs.github.com/."
      )
    end

    libs_part = Enum.join(native.libs, " ")

    unquoted_dir_part =
      native.app
      |> Toolchain.output_path(:nif)
      |> PathHelper.fix_slashes()

    dir_part = "\"#{unquoted_dir_part}\""

    [
      "(if exist #{dir_part} rmdir /S /Q #{dir_part})",
      "(mkdir #{dir_part})",
      ~s[(cl /LD #{includes_part} #{sources_part} #{libs_part} /link /DLL /OUT:"#{Toolchain.output_path(native.app, native.name, :nif) |> PathHelper.fix_slashes}.dll")]
    ]
  end

  # Runs vcvarsall.bat script
  defp run_vcvarsall(vcvarsall_arg) do
    program_files = System.get_env("ProgramFiles(x86)") |> Path.expand()
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
         {maybe_installation_path, 0} <- System.cmd(vswhere, vswhere_args)
    do
      installation_path = String.trim(maybe_installation_path)
      Path.join([installation_path, "VC", "Auxiliary", "Build", "vcvarsall.bat"])
      |> PathHelper.fix_slashes()
    end
  end
end
