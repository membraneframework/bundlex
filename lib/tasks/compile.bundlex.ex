defmodule Mix.Tasks.Compile.Bundlex do
  use Mix.Task
  alias Bundlex.{BuildScript, NIF, Output, Platform, Project}
  alias Bundlex.Helper.MixHelper

  @moduledoc """
  Builds a library for the given platform.
  """

  @shortdoc "Builds a library for the given platform"

  @spec run(OptionParser.argv()) :: :ok
  def run(_args) do
    :ok = Application.ensure_started(:porcelain)
    :ok = MixHelper.store_project_dir()

    commands = []

    app = MixHelper.get_app!()
    Output.info_main("Bulding Bundlex Library: #{inspect(app)}")

    Output.info_stage("Reading project")

    project =
      with {:ok, project_module} <- Project.get(app) do
        project_module
      else
        {:error, reason} ->
          Output.raise("Cannot get project for app: #{inspect(app)}, reason: #{inspect(reason)}")
      end

    # Parse options
    Output.info_stage("Target platform")
    platform = Platform.get_current!()
    Output.info_substage("Building for platform #{platform}")

    # Toolchain
    Output.info_stage("Toolchain")
    commands = commands ++ Platform.get_module!(platform).toolchain_module.before_all!(platform)

    Output.info_stage("Resolving NIFs")

    commands =
      commands ++
        case NIF.resolve_nifs(app, project, platform) do
          {:ok, nifs_commands} -> nifs_commands
          {:error, reason} -> Output.raise("Error parsing NIFs, reason: #{inspect(reason)}")
        end

    Output.info_stage("Building")
    build_script = BuildScript.new(commands)

    if(
      (System.get_env("BUNDLEX_STORE_BUILD_SCRIPTS") || "false") |> String.downcase() == "true"
    ) do
      Output.info_substage("Storing build script")
      {:ok, {filename, _script}} = build_script |> BuildScript.store(platform)
      Output.info_substage("Stored #{File.cwd!() |> Path.join(filename)}")
    end

    Output.info_substage("Running build script")

    case build_script |> BuildScript.run(platform) do
      :ok ->
        :ok

      {:error, {:run_build_script, return_code: ret, command: cmd}} ->
        Output.raise("Build script:\n\n#{cmd}\n\nreturned non-zero code: #{ret}")

      {:error, reason} ->
        Output.raise("Error running build script, reason #{inspect(reason)}")
    end

    Output.info_stage("Done")
  end
end
