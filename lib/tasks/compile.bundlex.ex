defmodule Mix.Tasks.Compile.Bundlex do
  @shortdoc "Builds natives specified in bundlex.exs file"
  @moduledoc """
  #{@shortdoc}

  Accepts the following command line arguments:
  - `--platform <platform>` - platform to build for, see `Bundlex.platform/0`.
  - `--store-scripts` - if set, shell scripts are stored in the project
  root folder for further analysis.

  Add `:bundlex` to compilers in your Mix project to have this task executed
  each time the project is compiled.
  """

  use Mix.Task.Compiler
  alias Bundlex.{BuildScript, Native, Output, Platform, Project}
  alias Bundlex.Helper.MixHelper

  @impl true
  def run(_args) do
    {:ok, _apps} = Application.ensure_all_started(:bundlex)
    commands = []

    app = MixHelper.get_app!()
    Output.info_main("Bulding Bundlex Library: #{inspect(app)}")

    Output.info_stage("Reading project")

    project =
      with {:ok, project} <- Project.get(app) do
        project
      else
        {:error, reason} ->
          Output.raise("Cannot get project for app: #{inspect(app)}, reason: #{inspect(reason)}")
      end

    # Parse options
    Output.info_stage("Target platform")
    platform = Bundlex.platform()
    Output.info_substage("Building for platform #{platform}")

    # Toolchain
    Output.info_stage("Toolchain")
    commands = commands ++ Platform.get_module(platform).toolchain_module.before_all!(platform)

    Output.info_stage("Resolving Natives")

    commands =
      commands ++
        case Native.resolve_natives(project, platform) do
          {:ok, nifs_commands} -> nifs_commands
          {:error, reason} -> Output.raise("Error parsing Natives, reason: #{inspect(reason)}")
        end

    Output.info_stage("Building")
    build_script = BuildScript.new(commands)

    {cmdline_options, _argv, _errors} =
      OptionParser.parse(System.argv(), switches: [store_scripts: :boolean])

    if(cmdline_options[:store_scripts]) do
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
    :ok
  end
end
