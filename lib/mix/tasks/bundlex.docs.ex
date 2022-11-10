defmodule Mix.Tasks.Bundlex.Docs do
  use Mix.Task

  alias Bundlex.{Output, Project}
  alias Bundlex.Helper.MixHelper
  alias Bundlex.Doxygen.Generator

  @impl Mix.Task
  def run(_args) do
    {:ok, _apps} = Application.ensure_all_started(:bundlex)
    # commands = []

    app = MixHelper.get_app!()
    # platform = Bundlex.platform()

    project =
      with {:ok, project} <- Project.get(app) do
        project
      else
        {:error, reason} ->
          Output.raise("Cannot get project for app: #{inspect(app)}, reason: #{inspect(reason)}")
      end

    doxygen = Generator.doxygen(project)

    if File.exists?(doxygen.doxyfile_path) do
      IO.puts("Doxyfile found at #{doxygen.doxyfile_path}. Do you want to overwrite it? [y/N]")
      ans = IO.read(:stdio, :line)

      if ans == "y" do
        Generator.generate_doxyfile(doxygen)
        IO.puts("Doxyfile generated at #{doxygen.doxyfile_path}")
      else
        IO.puts("Doxyfile not generated")
      end
    else
      Generator.generate_doxyfile(doxygen)
    end

    Generator.generate_doxygen(doxygen)

    # Mix.Task.run("docs", ["--formatter", "bundlex"])
  end
end
