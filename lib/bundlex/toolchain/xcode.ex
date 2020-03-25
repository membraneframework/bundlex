defmodule Bundlex.Toolchain.XCode do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.{Unix, Compilers}

  @compilers %Compilers{c: "cc", cpp: "clang++"}

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-dynamiclib -undefined dynamic_lookup"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    compiler = @compilers |> Map.get(native.language)

    Unix.compiler_commands(
      native,
      "#{compiler} #{cflags}",
      "#{compiler} #{lflags}",
      native.language,
      wrap_deps: &"-Wl,-all_load #{&1}"
    )
  end
end
