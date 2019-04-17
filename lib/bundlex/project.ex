defmodule Bundlex.Project do
  @bundlex_file_name "bundlex.exs"
  @moduledoc """
  Behaviour that should be implemented by each project using Bundlex in the
  `#{@bundlex_file_name}` file.
  """
  use Bunch
  alias Bunch.KVList
  alias Bundlex.Helper.MixHelper
  alias __MODULE__.Store

  @src_dir_name "c_src"

  @type native_name_t :: atom

  @typedoc """
  Type describing configuration of a native.

  It's a keyword list containing the following keys:
  * `sources` - C files to be compiled (at least one must be provided),
  * `includes` - Paths to look for header files (empty list by default).
  * `libs_dirs` - Paths to look for libraries (empty list by default).
  * `libs` - Names of libraries to link (empty list by default).
  * `pkg_configs` - Names of libraries for which the appropriate flags will be
  obtained using pkg-config (empty list by default).
  * `deps` - Dependencies in the form of `{app, lib_name}`, where `app`
  is the application name of the dependency, and `lib_name` is the name of lib
  specified in bundlex project of this dependency.
  * `src_base` - Native files should reside in `project_root/c_src/<src_base>`
  (application name by default).
  * `compiler_flags` - Custom flags for compiler.
  * `linker_flags` - Custom flags for linker.
  """
  @type native_config_t :: [
          sources: [String.t()],
          includes: [String.t()],
          lib_dirs: [String.t()],
          libs: [String.t()],
          pkg_configs: [String.t()],
          deps: [{Application.app(), native_name_t | [native_name_t]}],
          src_base: String.t(),
          compiler_flags: [String.t()],
          linker_flags: [String.t()]
        ]

  @typedoc """
  Type describing project configuration.

  It's a keyword list, where nifs, cnodes and libs can be specified. Libs are
  native packages that are compiled as static libraries and linked to natives
  that have them specified in `deps` field of their configuration.
  """
  @type config_t :: KVList.t(:nifs | :cnodes | :libs, KVList.t(native_name_t, native_config_t))

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

  @typedoc """
  Struct representing bundlex project.

  Contains the following fileds:
  - `:config` - project configuration
  - `:src_path` - path to the native sources
  - `:module` - bundlex project module
  - `:app` - application that exports project
  """
  @type t :: %__MODULE__{config: config_t, src_path: String.t(), module: module, app: atom}

  @enforce_keys [:config, :src_path, :module, :app]
  defstruct @enforce_keys

  @doc """
  Determines if `module` is a bundlex project module.
  """
  @spec project_module?(module) :: boolean
  def project_module?(module) do
    function_exported?(module, :bundlex_project?, 0) and module.bundlex_project?()
  end

  @doc """
  Returns the project struct of given application.

  If the module has not been loaded yet, it is loaded from
  `project_dir/#{@bundlex_file_name}` file.
  """
  @spec get(application :: atom) ::
          {:ok, t}
          | {:error,
             :invalid_project_specification
             | {:no_bundlex_project_in_file, path :: binary()}
             | :unknown_application}
  def get(application \\ MixHelper.get_app!()) do
    project = Store.get_project(application)

    if project do
      {:ok, project}
    else
      with {:ok, module} <- load(application),
           project = %__MODULE__{
             config: module.project(),
             src_path: module.src_path(),
             module: module,
             app: application
           },
           true <- Keyword.keyword?(project.config) or {:error, :invalid_project_specification} do
        Store.store_project(application, project)
        {:ok, project}
      end
    end
  end

  @spec load(application :: atom) ::
          {:ok, module}
          | {:error, {:no_bundlex_project_in_file, path :: binary()} | :unknown_application}
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
