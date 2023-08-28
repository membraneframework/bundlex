defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Native
  alias Bundlex.Toolchain.Common.{Compilers, Unix}

  @compilers %Compilers{c: "gcc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native do
        # zmiana "-fPIC, "-rdynamic -shared"
        %Native{type: :native, interface: :nif} -> {"", ""}
        %Native{type: :lib} -> {"-fPIC", ""}
        %Native{} -> {"", ""}
      end

    compiler = @compilers |> Map.get(native.language)

    Unix.compiler_commands(
      native,
      "#{compiler} #{cflags}",
      "#{compiler} #{lflags}",
      native.language,
      # zmiana  -Wl,--no-whole-archive
      wrap_deps: &"-Wl,--whole-archive #{&1}"
    )
  end
end
