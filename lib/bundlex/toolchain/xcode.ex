defmodule Bundlex.Toolchain.XCode do
  @moduledoc """
  Toolchain definition for XCode.
  """

  use Bundlex.Toolchain


  def compiler_commands(includes, libs, sources, pkg_configs, output) do
    # FIXME escape quotes properly

    includes_part = includes |> Enum.map(fn(include) -> "-I\"#{include}\"" end) |> Enum.join(" ")
    sources_part = sources |> Enum.map(fn(source) -> "\"#{source}\"" end) |> Enum.join(" ")
    libs_part = libs |> Enum.map(fn(lib) -> "-l#{lib}" end) |> Enum.join(" ")
    pkg_configs_part = pkg_configs |> Enum.map(fn(pkg_config) ->
      %Porcelain.Result{status: 0, out: out} = Porcelain.exec("pkg-config", ["--cflags", "--libs", pkg_config])
      out |> String.trim
    end) |> Enum.join(" ")

    ["mkdir -p priv/lib", "cc -fPIC -W -dynamiclib -undefined dynamic_lookup -o priv/lib/#{output}.so #{includes_part} #{libs_part} #{pkg_configs_part} #{sources_part}"]
  end
end
