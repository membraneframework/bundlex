defmodule Mix.Tasks.Bundlex.Docs do
  @shortdoc "Generates doxygen documentation for Bundlex project"
  @moduledoc """
  #{@shortdoc}

  Accepts the following command line arguments:
  - `--store-scripts` - if set, shell scripts are stored in the project
  root folder for further analysis.

  Add `:bundlex` to compilers in your Mix project to have this task executed
  each time the project is compiled.
  """

  use Mix.Task

  alias Bundlex.{Output, Project}
  alias Bundlex.Doxygen.Generator
  alias Bundlex.Helper.MixHelper

  @impl Mix.Task
  def run(_args) do
    {:ok, _apps} = Application.ensure_all_started(:bundlex)
    # commands = []

    app = MixHelper.get_app!()
    # platform = Bundlex.platform()

    project = get_project(app)

    doxygen = Generator.doxygen(project)

    overwrite_dialogue(doxygen, doxygen.doxyfile_path, &Generator.generate_doxyfile/1)

    Generator.generate_doxygen(doxygen)

    overwrite_dialogue(doxygen, doxygen.page_path, &Generator.generate_hex_page/1)

    example_docs = """
    defp docs do
      [
        extras: [
          "#{doxygen.page_path}",
          ...
        ],
        ...
      ]
    end
    """

    Output.info(
      "Put \"#{doxygen.page_path}\" in the extras section of docs in the mix.exs and then run mix docs.\nExample:\n#{example_docs}"
    )

    # Mix.Task.run("docs", ["--formatter", "bundlex"])
  end

  defp get_project(app) do
    with {:ok, project} <- Project.get(app) do
      project
    else
      {:error, reason} ->
        Output.raise("Cannot get project for app: #{inspect(app)}, reason: #{inspect(reason)}")
    end
  end

  defp overwrite_dialogue(doxygen, filepath, generator) do
    if File.exists?(filepath) do
      Output.info("Found #{filepath}. Do you want to overwrite it? [y/N]")
      ans = IO.read(:stdio, :line)

      if String.downcase(ans) == "y" do
        generator.(doxygen)
        Output.info("Generated")
      else
        Output.info("Skipped")
      end
    else
      generator.(doxygen)
    end
  end
end
