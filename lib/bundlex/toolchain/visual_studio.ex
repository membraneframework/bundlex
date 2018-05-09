defmodule Bundlex.Toolchain.VisualStudio do
  @moduledoc """
  Toolchain definition for Microsoft Visual Studio.

  It tries to determine Visual Studio root directory before compolation starts
  and set up appropriate environment variables that will cause using right
  compiler for given platform by calling vcvarsall.bat script shipped with
  Visual Studio.

  Visual Studio directory may be override by setting VISUAL_STUDIO_ROOT
  environment variable.
  """

  use Bundlex.Toolchain
  alias Bundlex.Helper.{DirectoryHelper, GitHelper}
  alias Bundlex.Output

  @directory_wildcard_x64 "c:\\Program Files (x86)\\Microsoft Visual Studio *"
  @directory_wildcard_x86 "c:\\Program Files\\Microsoft Visual Studio *"
  @directory_env "VISUAL_STUDIO_ROOT"

  def before_all!(:windows32) do
    [run_vcvarsall("x86")]
  end

  def before_all!(:windows64) do
    [run_vcvarsall("amd64")]
  end

  def compiler_commands(nif, app_name, nif_name) do
    # FIXME escape quotes properly

    includes_part =
      nif.includes
      |> Enum.map(fn include -> "/I \"#{DirectoryHelper.fix_slashes(include)}\"" end)
      |> Enum.join(" ")

    sources_part =
      nif.sources
      |> Enum.map(fn source -> "\"#{DirectoryHelper.fix_slashes(source)}\"" end)
      |> Enum.join(" ")

    if not (nif.libs |> Enum.empty?()) and not GitHelper.lfs_present?() do
      Output.raise(
        "Git LFS is not installed, being necessary for downloading windows *.lib files for dlls #{
          inspect(nif.libs)
        }. Install from https://git-lfs.github.com/."
      )
    end

    libs_part = nif.libs |> Enum.join(" ")

    [
      "mkdir #{Toolchain.output_path(app_name)}",
      "cl /LD #{includes_part} #{sources_part} #{libs_part} /link /OUT:#{
        Toolchain.output_path(app_name, nif_name)
      }.dll"
    ]
  end

  # Runs vcvarsall.bat script
  defp run_vcvarsall(vcvarsall_arg) do
    vcvarsall_path =
      determine_visual_studio_root()
      |> build_vcvarsall_path()

    case File.exists?(vcvarsall_path) do
      false ->
        Output.raise(
          "Unable to find vcvarsall.bat script within Visual Studio root directory. Is your Visual Studio installation valid? (and file is in VC directory?)"
        )

      true ->
        Bundlex.Output.info_substage("Adding call to \"vcvarsall.bat #{vcvarsall_arg}\"")

        "call \"#{vcvarsall_path}\" #{vcvarsall_arg}"
    end
  end

  # Determines root directory of the Visual Studio.
  defp determine_visual_studio_root() do
    determine_visual_studio_root(System.get_env(@directory_env))
  end

  # Determines root directory of the Visual Studio.
  # Case when we don't have a root path passed via an environment variable.
  defp determine_visual_studio_root(nil) do
    visual_studio_path()
    |> determine_visual_studio_root_with_wildcard()
  end

  # Determines root directory of the Visual Studio.
  # Case when we have a root path passed via an environment variable.
  defp determine_visual_studio_root(directory) do
    Bundlex.Output.info_substage(
      "Using #{directory} passed via #{@directory_env} environment variable as Visual Studio root."
    )

    directory
  end

  defp determine_visual_studio_root_with_wildcard(wildcard) do
    Bundlex.Output.info_substage("Trying to find Visual Studio in \"#{wildcard}\"...")

    case DirectoryHelper.wildcard(wildcard) do
      nil ->
        Output.raise(
          "Unable to find Visual Studio root directory. Please ensure that it is either located in \"#{
            wildcard
          }\" or #{@directory_env} environment variable pointing to its root is set."
        )

      directory ->
        Bundlex.Output.info_substage("Found Visual Studio in #{directory}")

        directory
    end
  end

  # Builds path to the vcvarsall.bat script that can be used to set environment
  # variables necessary to use Visual Studio compilers.
  defp build_vcvarsall_path(root) do
    Path.join([root, "VC", "vcvarsall.bat"])
  end

  defp visual_studio_path() do
    case :erlang.system_info(:wordsize) do
      4 -> @directory_wildcard_x86
      _ -> @directory_wildcard_x64
    end
  end
end
