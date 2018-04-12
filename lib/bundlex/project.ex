defmodule Bundlex.Project do
  defmacro __using__(_args) do
    quote do
      def bundlex_project?, do: true
    end
  end

  alias Bundlex.Helper.MixHelper
  use Bundlex.Helper

  @bundlex_file_name "bundlex.exs"

  def project_module?(module) do
    function_exported?(module, :bundlex_project?, 0)
    and module.bundlex_project?()
  end

  def get(application) do
    with {:ok, %Macro.Env{file: file}} <- MixHelper.get_mixfile_env(application) do
      bundlex_file_path = file |> Path.dirname() |> Path.join(@bundlex_file_name)
      modules = Code.require_file(bundlex_file_path) |> Keyword.keys
      modules
      |> Enum.find(&project_module?/1)
      |> Helper.wrap_nil({:error, {:no_bundlex_project_in_file, bundlex_file_path}})
    end
  end

end
