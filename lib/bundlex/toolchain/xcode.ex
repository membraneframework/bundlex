defmodule Bundlex.Toolchain.XCode do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.Unix

  @impl Toolchain
  def compiler_commands(native) do
    {cflags, lflags} =
      case native.type do
        :nif -> {"-fPIC", "-dynamiclib -undefined dynamic_lookup"}
        :lib -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    Unix.compiler_commands(native, "cc #{cflags}", "cc #{lflags}",
      wrap_deps: &"-Wl,-all_load #{&1}"
    )
  end
end
