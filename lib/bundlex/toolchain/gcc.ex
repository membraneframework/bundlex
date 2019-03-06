defmodule Bundlex.Toolchain.GCC do
  @moduledoc """
  Toolchain definition for GCC.
  """

  use Bundlex.Toolchain
  alias Bundlex.Native

  def compiler_commands(%Native{type: :nif} = native, app) do
    includes_part =
      native.includes |> Enum.map(fn include -> "-I\"#{include}\"" end) |> Enum.join(" ")

    libs_part = native.libs |> Enum.map(fn lib -> "-l#{lib}" end) |> Enum.join(" ")

    pkg_config_libs_part = native.pkg_configs |> Toolchain.pkg_config(["--libs"])
    pkg_config_cflags_part = native.pkg_configs |> Toolchain.pkg_config(["--cflags"])

    objects = native.sources |> Enum.map(fn source -> object_path(source) end) |> Enum.join(" ")

    commands_sources =
      native.sources
      |> Enum.map(fn source ->
        "gcc -fPIC -std=c11 -Wall -Wextra -O2 -g #{includes_part} #{libs_part} #{
          pkg_config_cflags_part
        } #{source_path(source)} -c -o #{object_path(source)}"
      end)

    commands_linker = [
      "gcc -rdynamic -undefined -shared #{objects} #{libs_part} #{pkg_config_libs_part} -o \"#{
        Toolchain.output_path(app, native.name)
      }.so\""
    ]

    ["mkdir -p \"#{Toolchain.output_path(app)}\""] ++ commands_sources ++ commands_linker
  end

  defp source_path(source), do: "\"#{source}\""

  defp object_path(source), do: "\"#{source}.o\"" |> String.replace(~r(\.c\.o"$), ".o\"")
end
