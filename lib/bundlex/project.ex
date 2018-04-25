defmodule Bundlex.Project do
  alias Bundlex.Helper.MixHelper
  use Bundlex.Helper

  @src_dir_name "c_src"
  @bundlex_file_name "bundlex.exs"

  @project_store_name :bundlex_project_store

  @type nif_name_t :: atom

  @typedoc """
  Type describing NIF configuration keyword list. Configuration
  consists of fields:
  * `sources` - C files to be compiled (at least one must be provided),
  * `includes` - Paths to look for header files (empty list by default).
  * `libs` - Names of libraries to link (empty list by default).
  * `pkg_configs` - Names of libraries that should be linked with pkg config (empty list by default).
  * `deps` - Dependencies in the form `{app_name, nif_name}`, where `app_name` is the application name of the dependency, and `nif_name` is the name of nif specified in bundlex file of this dependency. Sources, includes,
  libs and pkg_configs from those nifs will be appended. Empty list by default.
  * `export_only?` - Flag specifying whether NIF is only to be added as dependency and should not be compiled itself. `false` by default.
  * `src_base` - Native files should reside in `project_root/c_src/<src_base>`.
  Current app name by default.
  """
  @type nif_config_t :: [
          sources: [String.t()],
          includes: [String.t()],
          libs: [String.t()],
          pkg_configs: [String.t()],
          deps: [{Application.app(), nif_name_t}],
          export_only?: boolean,
          src_base: String.t()
        ]

  @type config_t :: [
          nif: [{nif_name_t, nif_config_t}]
        ]

  @callback project() :: config_t

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)
      def bundlex_project?, do: true
      def src_path, do: __DIR__ |> Path.join(unquote(@src_dir_name))
    end
  end

  def project_module?(module) do
    function_exported?(module, :bundlex_project?, 0) and module.bundlex_project?()
  end

  def get(application \\ MixHelper.get_app!()) do
    Agent.start(fn -> %{} end, name: @project_store_name)
    module = Agent.get(@project_store_name, & &1[application])

    if module do
      {:ok, module}
    else
      with {:ok, module} <- get_module_from_project_file(application) do
        Agent.update(@project_store_name, &(&1 |> Map.put(application, module)))
        {:ok, module}
      end
    end
  end

  defp get_module_from_project_file(application) do
    with {:ok, %Macro.Env{file: file}} <- MixHelper.get_mixfile_env(application) do
      bundlex_file_path = file |> Path.dirname() |> Path.join(@bundlex_file_name)
      modules = Code.require_file(bundlex_file_path) |> Keyword.keys()

      modules
      |> Enum.find(&project_module?/1)
      |> Helper.wrap_nil({:no_bundlex_project_in_file, bundlex_file_path})
    end
  end
end
