defmodule Bundlex.NIF do
  use Bundlex.Helper
  alias Helper.{EnumHelper, ErlangHelper}
  alias Bundlex.{Project, Output}

  def resolve_nifs(project, platform) do
    {platform_name, platform_module} = platform
    with {:ok, nifs} <- get_nifs(project) do
     if nifs |> Enum.empty? do
       Output.info_substage "No nifs found"
       {:ok, []}
     else
       erlang_includes = ErlangHelper.get_includes!(platform_name)
       Output.info_substage "Found Erlang includes: #{inspect erlang_includes}"
       nifs |> EnumHelper.flat_map_with(& resolve_nif &1, erlang_includes, project.src_path, platform_module)
     end
    else
      {:error, reason} -> {:error, {project, reason}}
    end
  end

  defp resolve_nif({nif_name, nif_config}, erlang_includes, src_path, platform_module) do
    with {:ok, nif} <- parse_nif({nif_name, nif_config}, src_path) do
      commands = platform_module.toolchain_module.compiler_commands(
        erlang_includes ++ nif.includes, nif.libs, nif.sources, nif.pkg_configs, nif_name)
      {:ok, commands}
    end
  end

  defp parse_nif({nif_name, nif_config}, src_path) do
    Output.info_substage "Parsing NIF #{inspect nif_name}"

    keys = [:includes, :libs, :pkg_configs, :sources]
    defaults = keys |> Enum.map(& {&1, []})
    values = nif_config |> Keyword.take(keys)
    values = defaults |> Keyword.merge(values) |> Map.new

    parse_src = fn ->
      if values.sources |> Enum.empty?,
      do: {:error, {:no_sources_in_nif, nif_name}},
      else: :ok
    end

    values = values
    |> Map.update!(:includes, & [src_path | &1])
    |> Map.update!(:sources, fn src -> src |> Enum.map(& Path.join(src_path, &1)) end)

    get_deps = fn ->
      nif_config
      |> Keyword.get(:deps, [])
      |> EnumHelper.flat_map_with(fn {app, nifs} ->
          with {:ok, project} <- app |> Project.get() do
                parse_deps(project, nifs |> Helper.listify)
          end
        end)
    end

    with :ok <- parse_src.(),
         {:ok, parsed_deps} <- get_deps.() do
      parsed_deps
      |> Enum.reduce(values, & Map.merge(&1, &2, fn _k, v1, v2 -> v1 ++ v2 end))
      ~> (nif -> {:ok, nif})
    end

  end

  defp parse_deps(project, names) do
    with {:ok, nifs} <- get_nifs(project, names) do
      nifs |> EnumHelper.map_with(& parse_nif &1, project.src_path)
    else
      {:error, reason} -> {:error, {project, reason}}
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
    diff = filtered_nifs
    |> Keyword.keys
    |> MapSet.new
    |> MapSet.difference(names |> MapSet.new)
    if diff |> Enum.empty? do
      {:ok, filtered_nifs}
    else
      {:error, {:nifs_not_found, diff |> Enum.to_list}}
    end
  end


end
