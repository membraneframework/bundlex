defmodule Bundlex.NIF do
  alias Bundlex.{Helper, Output, Platform, Project}
  alias Helper.ErlangHelper
  use Bunch

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
    with {:ok, nifs} <- get_nifs(project) do
      if nifs |> Enum.empty?() do
        Output.info_substage("No nifs found")
        {:ok, []}
      else
        erlang_includes = ErlangHelper.get_includes!(platform)
        Output.info_substage("Found Erlang includes: #{inspect(erlang_includes)}")

        nifs
        |> Bunch.Enum.try_flat_map(
          &resolve_nif(&1, erlang_includes, project.src_path, platform, app)
        )
      end
    else
      {:error, reason} -> {:error, {project, reason}}
    end
  end

  defp resolve_nif({nif_name, nif_config}, erlang_includes, src_path, platform, app) do
    with {:export_only?, false} <-
           {:export_only?, nif_config |> Keyword.get(:export_only?, false)},
         {:ok, nif} <- parse_nif({nif_name, nif_config}, src_path, app) do
      nif =
        nif
        |> Map.update!(:includes, &(erlang_includes ++ &1))
        |> Map.update!(:sources, &Enum.uniq/1)

      commands =
        Platform.get_module!(platform).toolchain_module.compiler_commands(nif, app, nif_name)

      {:ok, commands}
    else
      {:export_only?, true} ->
        Output.info_substage("Ignoring export-only nif #{inspect(nif_name)}")
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_nif({nif_name, nif_config}, src_path, app) do
    Output.info_substage("Parsing NIF #{inspect(nif_name)}")

    nif_config = nif_config |> Keyword.delete(:export_only?)
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
      |> Bunch.Enum.try_flat_map(fn {app, nifs} ->
        parse_deps(app, nifs |> Bunch.listify())
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
      nifs |> Bunch.Enum.try_map(&parse_nif(&1, project.src_path, app))
    else
      {:error, reason} -> {:error, {app, reason}}
    end
  end

  defp get_nifs(project, names \\ :all) do
    with {:config, config} when is_list(config) <- {:config, project.project()} do
      nifs = config |> Keyword.get(:nifs, [])
      nifs |> filter_nifs(names)
    else
      {:config, config} -> {:error, {:invalid_config, config}}
    end
  end

  defp filter_nifs(nifs, :all), do: {:ok, nifs}

  defp filter_nifs(nifs, names) do
    filtered_nifs = nifs |> Keyword.take(names)

    diff =
      names
      |> MapSet.new()
      |> MapSet.difference(filtered_nifs |> Keyword.keys() |> MapSet.new())

    if diff |> Enum.empty?() do
      {:ok, filtered_nifs}
    else
      {:error, {:nifs_not_found, diff |> Enum.to_list()}}
    end
  end
end
