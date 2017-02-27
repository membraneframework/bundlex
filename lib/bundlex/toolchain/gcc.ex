defmodule Bundlex.Toolchain.GCC do
  @moduledoc """
  Toolchain definition for GCC.
  """

  use Bundlex.Toolchain


  def compiler_commands(includes, libs, sources, output) do
    # FIXME escape quotes properly

    includes_part = includes |> Enum.map(fn(include) -> "-I\"#{include}\"" end) |> Enum.join(" ")
    sources_part = sources |> Enum.map(fn(source) -> "\"c_src/#{source}\"" end) |> Enum.join(" ")
    libs_part = libs |> Enum.map(fn(lib) -> "-l#{lib}" end) |> Enum.join(" ")

    ["gcc -fPIC -W -rdynamic -undefined -shared -o #{output}.so #{includes_part} #{libs_part} #{sources_part}"]
  end
end
