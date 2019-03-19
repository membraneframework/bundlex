defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.Unix

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-rdynamic -shared"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    Unix.compiler_commands(native, "gcc #{cflags}", "gcc #{lflags}",
      wrap_deps: &"-Wl,--whole-archive #{&1} -Wl,--no-whole-archive"
    )
  end
end
