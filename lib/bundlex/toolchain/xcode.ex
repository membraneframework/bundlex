defmodule Bundlex.Toolchain.XCode do
  @moduledoc """
  Toolchain definition for XCode.
  """

  use Bundlex.Toolchain


  def compiler_commands(nif, app_name, nif_name) do
    # FIXME escape quotes properly

    includes_part = nif.includes |> Enum.map(fn(include) -> "-I\"#{include}\"" end) |> Enum.join(" ")
    sources_part = nif.sources |> Enum.map(fn(source) -> "\"#{source}\"" end) |> Enum.join(" ")
    libs_part = nif.libs |> Enum.map(fn(lib) -> "-l#{lib}" end) |> Enum.join(" ")
    pkg_configs_part = nif.pkg_configs |> Enum.map(fn(pkg_config) ->
      %Porcelain.Result{status: 0, out: out} = Porcelain.exec("pkg-config", ["--cflags", "--libs", pkg_config])
      out |> String.trim
    end) |> Enum.join(" ")

    ["mkdir -p #{Toolchain.output_path(app_name)}", "cc -fPIC -W -dynamiclib -undefined dynamic_lookup -o #{Toolchain.output_path(app_name, nif_name)}.so #{includes_part} #{libs_part} #{pkg_configs_part} #{sources_part}"]
  end
end
