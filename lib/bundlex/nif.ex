defmodule Bundlex.Native do
  alias Bundlex.{Helper, Output, Platform, Project}
  alias Helper.ErlangHelper
  use Bunch

  @type t :: %__MODULE__{
          name: atom,
          type: :nif | :cnode | :lib,
          includes: [String.t()],
          libs: [String.t()],
          lib_dirs: [String.t()],
          pkg_configs: [String.t()],
          sources: [String.t()]
        }

  @enforce_keys [:name, :type]

  defstruct name: nil,
            type: nil,
            includes: [],
            libs: [],
            lib_dirs: [],
            pkg_configs: [],
            sources: []

  @native_type_keys %{nif: :nifs, cnode: :cnodes, lib: :libs}

  def resolve_natives(app, project, platform) do
    case get_native_configs(project, [:nif, :cnode]) do
      [] ->
        Output.info_substage("No natives found")
        {:ok, []}

      native_configs ->
        erlang = %{
          includes: ErlangHelper.get_includes(platform),
          lib_dirs: ErlangHelper.get_lib_dirs(platform)
        }

        Output.info_substage("Found Erlang includes: #{inspect(erlang.includes)}")
        Output.info_substage("Found Erlang lib dirs: #{inspect(erlang.lib_dirs)}")

        native_configs
        |> Bunch.Enum.try_flat_map(&resolve_native(&1, erlang, project.src_path, platform, app))
    end
  end

  defp resolve_native(config, erlang, src_path, platform, app) do
    with {:ok, native} <- parse_native(config, src_path, app) do
      native =
        case native.type do
          :cnode ->
            native
            |> Map.update!(:libs, &(["ei"] ++ &1))
            |> Map.update!(:lib_dirs, &(erlang.lib_dirs ++ &1))

          _ ->
            native
        end
        |> Map.update!(:includes, &(erlang.includes ++ &1))
        |> Map.update!(:sources, &Enum.uniq/1)

      commands = Platform.get_module!(platform).toolchain_module.compiler_commands(native, app)

      {:ok, commands}
    end
  end

  defp parse_native(config, src_path, app) do
    Output.info_substage("Parsing native #{inspect(config[:name])}")

    {deps, config} = config |> Keyword.pop(:deps, [])
    {src_base, config} = config |> Keyword.pop(:src_base, "#{app}")
    native = config |> __struct__()

    native =
      native
      |> Map.update!(:includes, &[src_path | &1])
      |> Map.update!(:sources, fn src -> src |> Enum.map(&Path.join([src_path, src_base, &1])) end)

    withl no_src: false <- native.sources |> Enum.empty?(),
          deps: {:ok, parsed_deps} <- parse_deps(deps) do
      parsed_deps
      |> Enum.reduce(native, &merge_lib/2)
      ~> (native -> {:ok, native})
    else
      no_src: true -> {:error, {:no_sources_in_native, native.name}}
      deps: error -> error
    end
  end

  defp get_native_configs(project, types) do
    types
    |> Bunch.listify()
    |> Enum.flat_map(fn type ->
      project.project()
      |> Keyword.get(@native_type_keys[type], [])
      |> Enum.map(fn {name, config} -> config ++ [name: name, type: type] end)
    end)
  end

  defp parse_deps(deps) do
    deps
    |> Bunch.Enum.try_flat_map(fn {app, natives} ->
      parse_app_deps(app, natives |> Bunch.listify())
    end)
  end

  defp parse_app_deps(app, names) do
    with {:ok, project} <- app |> Project.parse(),
         {:ok, libs} <- find_libs(project, names) do
      libs |> Bunch.Enum.try_map(&parse_native(&1, project.src_path, app))
    else
      {:error, reason} -> {:error, {app, reason}}
    end
  end

  defp find_libs(project, names) do
    names = names |> MapSet.new()
    found_libs = project |> get_native_configs(:lib) |> Enum.filter(&(&1[:name] in names))
    diff = names |> MapSet.difference(found_libs |> MapSet.new(& &1[:name]))

    if diff |> Enum.empty?() do
      {:ok, found_libs}
    else
      {:error, {:libs_not_found, diff |> Enum.to_list()}}
    end
  end

  defp merge_lib(%__MODULE__{type: :lib} = lib, %__MODULE__{} = native) do
    Map.merge(native, lib, fn
      :__struct__, __MODULE__, __MODULE__ -> __MODULE__
      :name, name, _lib_name -> name
      :type, type, :lib -> type
      _k, v1, v2 -> v1 ++ v2
    end)
  end
end
