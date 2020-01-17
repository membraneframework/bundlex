defmodule Bundlex.Toolchain.XCode do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.Unix
  alias Bundlex.Toolchain.Compilers

  @compilers %Compilers{c: "cc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-dynamiclib -undefined dynamic_lookup"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    compiler = Compilers.resolve_compiler(native.language, @compilers)
    Unix.compiler_commands(native, "#{compiler} #{cflags}", "#{compiler} #{lflags}",
      wrap_deps: &"-Wl,-all_load #{&1}"
    )
  end
end
