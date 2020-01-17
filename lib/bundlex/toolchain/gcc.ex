defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.{Unix, Compilers}

  @compilers %Compilers{c: "gcc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-rdynamic -shared"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    lang = Compilers.resolve_lang(native.language)
    compiler = Compilers.resolve_compiler(lang, @compilers)

    Unix.compiler_commands(native, "#{compiler} #{cflags}", "#{compiler} #{lflags}", lang,
      wrap_deps: &"-Wl,--whole-archive #{&1} -Wl,--no-whole-archive",
    )
  end
end
