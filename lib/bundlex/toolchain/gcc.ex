defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.Unix
  alias Bundlex.Toolchain.Compilers

  @compilers %Compilers{c: "gcc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-rdynamic -shared"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    compiler = Compilers.resolve_compiler(native.language, @compilers)
    Unix.compiler_commands(native, "#{compiler} #{cflags}", "#{compiler} #{lflags}",
      wrap_deps: &"-Wl,--whole-archive #{&1} -Wl,--no-whole-archive"
    )
  end
end
