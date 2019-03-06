defmodule Bundlex.Toolchain.XCode do
  @moduledoc """
  Toolchain definition for XCode.
  """

  use Bundlex.Toolchain

  def compiler_commands(native, app) do
    # FIXME escape quotes properly

    includes_part =
      native.includes |> Enum.map(fn include -> "-I\"#{include}\"" end) |> Enum.join(" ")

    sources_part = native.sources |> Enum.map(fn source -> "\"#{source}\"" end) |> Enum.join(" ")
    lib_dirs_part = native.lib_dirs |> Enum.map(fn lib -> "-L#{lib}" end) |> Enum.join(" ")
    libs_part = native.libs |> Enum.map(fn lib -> "-l#{lib}" end) |> Enum.join(" ")
    pkg_configs_part = native.pkg_configs |> Toolchain.pkg_config(["--cflags", "--libs"])

    [
      "mkdir -p \"#{Toolchain.output_path(app)}\"",
      "cc -Wall -Wextra #{flags(native.type)} \
      -o \"#{Toolchain.output_path(app, native.name)}#{ext(native.type)}\" \
      #{includes_part} #{lib_dirs_part} #{libs_part} #{pkg_configs_part} #{sources_part}"
    ]
  end

  defp flags(:nif), do: "-fPIC -dynamiclib -undefined dynamic_lookup"
  defp flags(:cnode), do: ""

  defp ext(:nif), do: ".so"
  defp ext(:cnode), do: ""
end
