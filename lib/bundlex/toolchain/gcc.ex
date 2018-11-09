defmodule Bundlex.Toolchain.GCC do
  @moduledoc """
  Toolchain definition for GCC.
  """

  use Bundlex.Toolchain

  def compiler_commands(nif, app_name, nif_name) do
    # FIXME escape quotes properly

    includes_part =
      nif.includes |> Enum.map(fn include -> "-I\"#{include}\"" end) |> Enum.join(" ")

    libs_part = nif.libs |> Enum.map(fn lib -> "-l#{lib}" end) |> Enum.join(" ")

    pkg_config_libs_part = Toolchain.pkg_config(nif, ["--libs"])
    pkg_config_cflags_part = Toolchain.pkg_config(nif, ["--cflags"])

    objects = nif.sources |> Enum.map(fn source -> object_path(source) end) |> Enum.join(" ")

    commands_sources =
      nif.sources
      |> Enum.map(fn source ->
        "gcc -fPIC -std=c11 -Wall -Wextra -O2 -g #{includes_part} #{libs_part} #{
          pkg_config_cflags_part
        } \"#{source_path(source)}\" -c -o \"#{object_path(source)}\""
      end)

    commands_linker = [
      "gcc -rdynamic -undefined -shared #{objects} #{libs_part} #{pkg_config_libs_part} -o #{
        Toolchain.output_path(app_name, nif_name)
      }.so"
    ]

    ["mkdir -p #{Toolchain.output_path(app_name)}"] ++ commands_sources ++ commands_linker
  end

  defp source_path(source), do: source

  defp object_path(source), do: "#{source}.o" |> String.replace(~r(\.c\.o$), ".o")
end
