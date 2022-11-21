defmodule Mix.Tasks.Bundlex.Doxygen do
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

  alias Bundlex.{Doxygen, Output, Project}
  alias Bundlex.Helper.MixHelper

  @impl Mix.Task
  def run(args) do
    skip_overwrite_check? = "-y" in args or "--yes" in args

    app = MixHelper.get_app!()

    project = get_project(app)

    doxygen = Doxygen.doxygen(project)

    Doxygen.generate_doxyfile(doxygen)

    Doxygen.generate_doxygen(doxygen)

    if skip_overwrite_check? do
      Doxygen.generate_hex_page(doxygen)
    else
      overwrite_dialogue(doxygen, doxygen.page_path, &Doxygen.generate_hex_page/1)
    end

    unless page_included?(doxygen.page_path) do
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

      Output.info("""
      Doxygen documentation page not included in the project docs.
      Add the following snippet to your mix.exs file:
      #{example_docs}
      """)
    end
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
      ans = IO.read(:stdio, :line) |> String.trim() |> String.downcase()

      if ans == "y" do
        generator.(doxygen)
        Output.info("Generated")
      else
        Output.info("Skipped")
      end
    else
      generator.(doxygen)
    end
  end

  defp page_included?(doxygen_page) do
    config = Mix.Project.config()

    with {:ok, docs} <- Keyword.fetch(config, :docs),
         {:ok, extras} <- Keyword.fetch(docs, :extras) do
      doxygen_page in extras
    else
      :error -> false
    end
  end
end
