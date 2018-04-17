defmodule Bundlex.NIF do
  use Bundlex.Helper
  alias Helper.{EnumHelper, ErlangHelper}
  alias Bundlex.{Project, Output}

  @type t :: %__MODULE__{
          includes: [String.t()],
          libs: [String.t()],
          pkg_configs: [String.t()],
          sources: [String.t()]
        }
  defstruct includes: [], libs: [], pkg_configs: [], sources: []

  def merge(%__MODULE__{} = nif1, %__MODULE__{} = nif2) do
    Map.merge(nif1, nif2, fn
      :__struct__, __MODULE__, __MODULE__ -> __MODULE__
      _k, v1, v2 -> v1 ++ v2
    end)
  end

  def resolve_nifs(app, project, platform) do
    {platform_name, platform_module} = platform

    with {:ok, nifs} <- get_nifs(project) do
      if nifs |> Enum.empty?() do
        Output.info_substage("No nifs found")
        {:ok, []}
      else
        erlang_includes = ErlangHelper.get_includes!(platform_name)
        Output.info_substage("Found Erlang includes: #{inspect(erlang_includes)}")

        nifs
        |> EnumHelper.flat_map_with(
          &resolve_nif(&1, erlang_includes, project.src_path, platform_module, app)
        )
      end
    else
      {:error, reason} -> {:error, {project, reason}}
    end
  end

  defp resolve_nif({nif_name, nif_config}, erlang_includes, src_path, platform_module, app) do
    with {:ok, nif} <- parse_nif({nif_name, nif_config}, src_path, app) do
      nif = nif |> Map.update!(:includes, &(erlang_includes ++ &1))
      commands = platform_module.toolchain_module.compiler_commands(nif, app, nif_name)
      {:ok, commands}
    end
  end

  defp parse_nif({nif_name, nif_config}, src_path, app) do
    Output.info_substage("Parsing NIF #{inspect(nif_name)}")

    {deps, nif_config} = nif_config |> Keyword.pop(:deps, [])
    {src_base, nif_config} = nif_config |> Keyword.pop(:src_base, "#{app}")
    values = nif_config |> __struct__()

    parse_src = fn ->
      if values.sources |> Enum.empty?(),
        do: {:error, {:no_sources_in_nif, nif_name}},
        else: :ok
    end

    values =
      values
      |> Map.update!(:includes, &[src_path | &1])
      |> Map.update!(:sources, fn src -> src |> Enum.map(&Path.join([src_path, src_base, &1])) end)

    get_deps = fn ->
      deps
      |> EnumHelper.flat_map_with(fn {app, nifs} ->
        parse_deps(app, nifs |> Helper.listify())
      end)
    end

    with :ok <- parse_src.(),
         {:ok, parsed_deps} <- get_deps.() do
      parsed_deps
      |> Enum.reduce(values, &merge/2)
      ~> (nif -> {:ok, nif})
    end
  end

  defp parse_deps(app, names) do
    with {:ok, project} <- app |> Project.get(),
         {:ok, nifs} <- get_nifs(project, names) do
      nifs |> EnumHelper.map_with(&parse_nif(&1, project.src_path, app))
    else
      {:error, reason} -> {:error, {app, reason}}
    end
  end

  defp get_nifs(project, names \\ :all) do
    with {:config, config} when is_list(config) <- {:config, project.project()} do
      nifs = config |> Keyword.get(:nif, [])
      nifs |> filter_nifs(names)
    else
      {:config, config} -> {:error, {:invalid_config, config}}
    end
  end

  defp filter_nifs(nifs, :all), do: {:ok, nifs}

  defp filter_nifs(nifs, names) do
    filtered_nifs = nifs |> Keyword.take(names)

    diff =
      filtered_nifs
      |> Keyword.keys()
      |> MapSet.new()
      |> MapSet.difference(names |> MapSet.new())

    if diff |> Enum.empty?() do
      {:ok, filtered_nifs}
    else
      {:error, {:nifs_not_found, diff |> Enum.to_list()}}
    end
  end
end
