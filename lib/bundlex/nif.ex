defmodule Bundlex.NIF do
  use Bundlex.Helper
  alias Helper.{EnumHelper, ErlangHelper}
  alias Bundlex.Output

  def parse_nifs(nifs, platform_name, platform_module) do
    erlang_includes = ErlangHelper.get_includes!(platform_name)
    Output.info_substage "Found Erlang includes: #{inspect erlang_includes}"

    nifs |> EnumHelper.flat_map_with(& parse_nif &1, erlang_includes, platform_module)
  end

  def parse_nif({nif_name, nif_config}, erlang_includes, platform_module) do
    Output.info_substage "Parsing NIF #{inspect nif_name}"
    includes = nif_config |> Keyword.get(:includes, [])
    includes = erlang_includes ++ includes
    libs = nif_config |> Keyword.get(:libs, [])
    pkg_configs = nif_config |> Keyword.get(:pkg_configs, [])
    sources = nif_config |> Keyword.get(:sources, [])
    cond do
      sources |> Enum.empty? -> {:error, {:no_sources_in_nif, nif_name}}
      true -> {:ok, platform_module.toolchain_module.compiler_commands(includes, libs, sources, pkg_configs, nif_name)}
    end
  end

end
