defmodule Bundlex.Toolchain.XCode do
  @moduledoc """
  Toolchain definition for XCode.
  """

  use Bundlex.Toolchain

  def compiler_commands(nif, app_name, nif_name) do
    # FIXME escape quotes properly

    includes_part =
      nif.includes |> Enum.map(fn include -> "-I\"#{include}\"" end) |> Enum.join(" ")

    sources_part = nif.sources |> Enum.map(fn source -> "\"#{source}\"" end) |> Enum.join(" ")
    libs_part = nif.libs |> Enum.map(fn lib -> "-l#{lib}" end) |> Enum.join(" ")

    pkg_configs_part = Toolchain.pkg_config(nif, ["--cflags", "--libs"])

    [
      "mkdir -p \"#{Toolchain.output_path(app_name)}\"",
      "cc -fPIC -Wall -Wextra -dynamiclib -undefined dynamic_lookup -o \"#{
        Toolchain.output_path(app_name, nif_name)
      }.so\" #{includes_part} #{libs_part} #{pkg_configs_part} #{sources_part}"
    ]
  end
end
