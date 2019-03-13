defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.Unix

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-rdynamic -undefined dynamic_lookup -shared"}
        _ -> {"", ""}
      end

    Unix.compiler_commands(native, "gcc #{cflags}", "gcc #{lflags}")
  end
end
