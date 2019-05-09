defmodule Bundlex.Native do
  @moduledoc false

  alias Bundlex.{Helper, Output, Platform, Project}
  alias Helper.ErlangHelper
  use Bunch

  @type t :: %__MODULE__{
          name: atom,
          app: atom,
          type: :nif | :cnode | :lib,
          includes: [String.t()],
          libs: [String.t()],
          lib_dirs: [String.t()],
          pkg_configs: [String.t()],
          sources: [String.t()],
          deps: [String.t()],
          compiler_flags: [String.t()],
          linker_flags: [String.t()]
        }

  @enforce_keys [:name, :type]

  defstruct name: nil,
            app: nil,
            type: nil,
            includes: [],
            libs: [],
            lib_dirs: [],
            pkg_configs: [],
            sources: [],
            deps: [],
            compiler_flags: [],
            linker_flags: []

  @project_keys [
    :includes,
    :libs,
    :lib_dirs,
    :pkg_configs,
    :sources,
    :deps,
    :compiler_flags,
    :linker_flags
  ]

  @native_type_keys %{nif: :nifs, cnode: :cnodes, lib: :libs}

  def resolve_natives(project, platform) do
    case get_native_configs(project) do
      [] ->
        Output.info("No natives found")
        {:ok, []}

      native_configs ->
        erlang = %{
          includes: ErlangHelper.get_includes(platform),
          lib_dirs: ErlangHelper.get_lib_dirs(platform)
        }

        Output.info(
          "Building natives: #{native_configs |> Enum.map(& &1.name) |> Enum.join(", ")}"
        )

        native_configs
        |> Bunch.Enum.try_flat_map(&resolve_native(&1, erlang, project.src_path, platform))
    end
  end

  defp resolve_native(config, erlang, src_path, platform) do
    with {:ok, native} <- parse_native(config, src_path) do
      native =
        case native.type do
          :cnode ->
            native
            |> Map.update!(:libs, &["pthread", "ei" | &1])
            |> Map.update!(:lib_dirs, &(erlang.lib_dirs ++ &1))

          _ ->
            native
        end
        |> Map.update!(:includes, &(erlang.includes ++ &1))
        |> Map.update!(:sources, &Enum.uniq/1)
        |> Map.update!(:deps, &Enum.uniq/1)

      commands = Platform.get_module(platform).toolchain_module.compiler_commands(native)

      {:ok, commands}
    end
  end

  defp parse_native(config, src_path) do
    {config, meta} = config |> Map.pop(:config)
    {deps, config} = config |> Keyword.pop(:deps, [])
    {src_base, config} = config |> Keyword.pop(:src_base, "#{meta.app}")

    withl fields: [] <- config |> Keyword.keys() |> Enum.reject(&(&1 in @project_keys)),
          do: native = (config ++ Enum.to_list(meta)) |> __struct__(),
          no_src: false <- native.sources |> Enum.empty?(),
          deps: {:ok, parsed_deps} <- parse_deps(deps) do
      native =
        native
        |> Map.update!(:includes, &[Path.join([src_path, src_base, ".."]) | &1])
        |> Map.update!(:sources, fn src ->
          src |> Enum.map(&Path.join([src_path, src_base, &1]))
        end)

      [native | parsed_deps]
      |> Enum.reduce(&add_lib/2)
      ~> {:ok, &1}
    else
      fields: fields -> {:error, {:unknown_fields, fields}}
      no_src: true -> {:error, {:no_sources_in_native, native.name}}
      deps: error -> error
    end
  end

  defp get_native_configs(project, types \\ [:lib, :nif, :cnode]) do
    types
    |> Bunch.listify()
    |> Enum.flat_map(fn type ->
      project.config
      |> Keyword.get(@native_type_keys[type], [])
      |> Enum.map(fn {name, config} ->
        %{config: config, name: name, type: type, app: project.app}
      end)
    end)
  end

  defp parse_deps(deps) do
    deps
    |> Bunch.Enum.try_flat_map(fn {app, natives} ->
      parse_app_libs(app, natives |> Bunch.listify())
    end)
  end

  defp parse_app_libs(app, names) do
    with {:ok, project} <- app |> Project.get(),
         {:ok, libs} <- find_libs(project, names) do
      libs |> Bunch.Enum.try_map(&parse_native(&1, project.src_path))
    else
      {:error, reason} -> {:error, {app, reason}}
    end
  end

  defp find_libs(project, names) do
    names = names |> MapSet.new()
    found_libs = project |> get_native_configs(:lib) |> Enum.filter(&(&1.name in names))
    diff = names |> MapSet.difference(found_libs |> MapSet.new(& &1.name))

    if diff |> Enum.empty?() do
      {:ok, found_libs}
    else
      {:error, {:libs_not_found, diff |> Enum.to_list()}}
    end
  end

  defp add_lib(%__MODULE__{type: :lib} = lib, %__MODULE__{} = native) do
    native
    |> Map.update!(:deps, &[{lib.app, lib.name} | &1])
    |> Map.merge(
      lib |> Map.take([:includes, :libs, :lib_dirs, :pkg_configs, :linker_flags, :deps]),
      fn _k, v1, v2 -> v2 ++ v1 end
    )
  end
end
