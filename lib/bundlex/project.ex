defmodule Bundlex.Project do
  alias Bundlex.Helper.MixHelper
  use Bundlex.Helper

  @src_dir_name "c_src"
  @bundlex_file_name "bundlex.exs"

  defmacro __using__(_args) do
    quote do
      def bundlex_project?, do: true
      def src_path, do: __DIR__ |> Path.join(unquote(@src_dir_name))
    end
  end

  def project_module?(module) do
    function_exported?(module, :bundlex_project?, 0)
    and module.bundlex_project?()
  end

  def get(application) do
    with {:ok, %Macro.Env{file: file}} <- MixHelper.get_mixfile_env(application) do
      bundlex_file_path = file |> Path.dirname() |> Path.join(@bundlex_file_name)
      #FIXME: use Code.require_file and store project in agent for multiple usage
      modules = Code.load_file(bundlex_file_path) |> Keyword.keys
      modules
      |> Enum.find(&project_module?/1)
      |> Helper.wrap_nil({:no_bundlex_project_in_file, bundlex_file_path})
    end
  end

end
