defmodule Bundlex.Toolchain.XCode do
  @moduledoc """
  Toolchain definition for XCode.
  """

  use Bundlex.Toolchain


  def compiler_commands(includes, libs, sources, output) do
    # FIXME escape quotes properly

    includes_part = includes |> Enum.map(fn(include) -> "-I\"#{include}\"" end) |> Enum.join(" ")
    sources_part = sources |> Enum.map(fn(source) -> "\"c_src/#{source}\"" end) |> Enum.join(" ")
    libs_part = libs |> Enum.map(fn(lib) -> "-l#{lib}" end) |> Enum.join(" ")

    ["cc -fPIC -W -dynamiclib -undefined dynamic_lookup -o #{output}.so #{includes_part} #{libs_part} #{sources_part}"]
  end
end
