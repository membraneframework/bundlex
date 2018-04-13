defmodule Mix.Tasks.Compile.Bundlex.Lib do
  use Mix.Task
  alias Bundlex.{Project, Makefile, NIF, Output}
  alias Bundlex.Helper.MixHelper


  @moduledoc """
  Builds a library for the given platform.
  """

  @shortdoc "Builds a library for the given platform"

  @spec run(OptionParser.argv) :: :ok
  def run(_args) do
    :ok = Application.ensure_started(:porcelain)
    commands = []

    app = MixHelper.get_app!()
    Output.info_main "Bulding Bundlex Library: #{inspect app}"

    Output.info_stage("Reading project")
    project = with {:ok, project_module} <- Project.get(app) do
              project_module
            else
              {:error, reason} -> Mix.raise("Cannot get project for app: #{inspect app}, reason: #{inspect reason}")
            end

    # Parse options
    Output.info_stage "Target platform"
    platform = {platform_name, platform_module} = Bundlex.Platform.get_current_platform!()
    Output.info_substage "Building for platform #{platform_name}"

    # Toolchain
    Output.info_stage "Toolchain"
    commands = commands ++ platform_module.toolchain_module.before_all!(platform_name)

    Output.info_stage "Resolving NIFs"
    commands = commands ++
      case NIF.resolve_nifs(project, platform) do
         {:ok, nifs_commands} -> nifs_commands
         {:error, reason} -> Mix.raise("Error parsing NIFs, reason: #{inspect reason}")
      end


    Output.info_stage "Building"
    makefile = Makefile.new(commands)
    Output.info_substage("Running makefile")
    makefile |> Makefile.run!(platform_name)
    if(System.get_env("BUNDLEX_STORE_MAKEFILES") || "false" |> String.downcase == "true") do
      Output.info_substage "Storing makefile"
      {:ok, filename} = makefile |> Makefile.store!(platform_name)
      Output.info_substage "Stored #{File.cwd! |> Path.join(filename)}"
    end
    Output.info_stage "Done"
  end


end
