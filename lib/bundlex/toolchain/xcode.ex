defmodule Bundlex.Toolchain.XCode do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.{Unix, Compilers}

  @compilers %Compilers{c: "cc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-dynamiclib -undefined dynamic_lookup"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    lang = Compilers.resolve_lang(native.language)
    compiler = Compilers.resolve_compiler(lang, @compilers)

    Unix.compiler_commands(native, "#{compiler} #{cflags}", "#{compiler} #{lflags}", lang,
      wrap_deps: &"-Wl,-all_load #{&1}"
    )
  end
end
