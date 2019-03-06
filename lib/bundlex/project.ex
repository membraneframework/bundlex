defmodule Bundlex.Project do
  use Bunch
  alias Bundlex.Helper.MixHelper

  @src_dir_name "c_src"
  @bundlex_file_name "bundlex.exs"

  @project_store_name :bundlex_project_store

  @type nif_name_t :: atom

  @typedoc """
  Type describing Native configuration keyword list. Configuration
  consists of fields:
  * `sources` - C files to be compiled (at least one must be provided),
  * `includes` - Paths to look for header files (empty list by default).
  * `libs` - Names of libraries to link (empty list by default).
  * `pkg_configs` - Names of libraries that should be linked with pkg config (empty list by default).
  * `deps` - Dependencies in the form `{app_name, nif_name}`, where `app_name` is the application name of the dependency, and `nif_name` is the name of nif specified in bundlex file of this dependency. Sources, includes,
  libs and pkg_configs from those nifs will be appended. Empty list by default.
  * `export_only?` - Flag specifying whether Native is only to be added as dependency and should not be compiled itself. `false` by default.
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

  @typedoc """
  Type describing project configuration.
  """
  @type config_t :: [
          nifs: [{nif_name_t, nif_config_t}]
        ]

  @doc """
  Callback returning project configuration.
  """
  @callback project() :: config_t

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)
      def bundlex_project?, do: true
      def src_path, do: __DIR__ |> Path.join(unquote(@src_dir_name))
    end
  end

  @doc """
  Determines if a module is a bundlex project module.
  """
  @spec project_module?(module) :: boolean
  def project_module?(module) do
    function_exported?(module, :bundlex_project?, 0) and module.bundlex_project?()
  end

  @doc """
  Returns the bundlex project module of given application. If the module has not
  been loaded yet, it is loaded from `project_dir/#{@bundlex_file_name}` file.
  """
  @spec get(application :: atom) :: {:ok, module} | {:error, any()}
  def get(application \\ MixHelper.get_app!()) do
    Agent.start(fn -> %{} end, name: @project_store_name)
    module = Agent.get(@project_store_name, & &1[application])

    if module do
      {:ok, module}
    else
      with {:ok, module} <- load(application) do
        Agent.update(@project_store_name, &(&1 |> Map.put(application, module)))
        {:ok, module}
      end
    end
  end

  def parse(application \\ MixHelper.get_app!()) do
    with {:ok, module} <- get(application) do
      project = module.project()

      if Keyword.keyword?(project) do
        {:ok, module}
      else
        {:error, :invalid_project_specification}
      end
    end
  end

  @spec load(application :: atom) :: {:ok, module} | {:error, any()}
  defp load(application) do
    with {:ok, dir} <- MixHelper.get_project_dir(application) do
      bundlex_file_path = dir |> Path.join(@bundlex_file_name)
      modules = Code.require_file(bundlex_file_path) |> Keyword.keys()

      modules
      |> Enum.find(&project_module?/1)
      |> Bunch.error_if_nil({:no_bundlex_project_in_file, bundlex_file_path})
    end
  end
end
