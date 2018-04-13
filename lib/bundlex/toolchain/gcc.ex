defmodule Bundlex.Toolchain.GCC do
  @moduledoc """
  Toolchain definition for GCC.
  """

  use Bundlex.Toolchain


  def compiler_commands(includes, libs, sources, pkg_configs, output) do
    # FIXME escape quotes properly

    includes_part = includes |> Enum.map(fn(include) -> "-I\"#{include}\"" end) |> Enum.join(" ")
    libs_part = libs |> Enum.map(fn(lib) -> "-l#{lib}" end) |> Enum.join(" ")

    pkg_config_libs_part = pkg_configs |> Enum.map(fn(pkg_config) ->
      %Porcelain.Result{status: 0, out: out} = Porcelain.exec("pkg-config", ["--libs", pkg_config])
      out |> String.trim
    end) |> Enum.join(" ")

    pkg_config_cflags_part = pkg_configs |> Enum.map(fn(pkg_config) ->
      %Porcelain.Result{status: 0, out: out} = Porcelain.exec("pkg-config", ["--cflags", pkg_config])
      out |> String.trim
    end) |> Enum.join(" ")

    objects = sources |> Enum.map(fn(source) -> object_path(source) end) |> Enum.join(" ")


    commands_sources =
      sources
      |> Enum.map(fn(source) ->
        "gcc -fPIC -std=c11 -W -O2 -g #{includes_part} #{libs_part} #{pkg_config_cflags_part} \"#{source_path(source)}\" -c -o \"#{object_path(source)}\""
      end)

    commands_linker =
      ["gcc -rdynamic -undefined -shared #{objects} #{libs_part} #{pkg_config_libs_part} -o priv/lib/#{output}.so"]

    ["mkdir -p priv/lib"] ++ commands_sources ++ commands_linker
  end


  defp source_path(source), do: source


  defp object_path(source), do: "#{source}.o" |> String.replace(~r(\.c\.o$), ".o")
end
