defmodule Bundlex.Toolchain.XCode do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.{Unix, Compilers}

  @compilers %Compilers{c: "cc", cpp: "clang++"}

  @impl Toolchain
  def compiler_commands(native, native_interface) do
    {cflags, lflags} =
      case {native, native_interface} do
        {%{type: :native}, :nif} -> {"-fPIC", "-dynamiclib -undefined dynamic_lookup"}
        {_native, :lib} -> {"-fPIC", ""}
        _ -> {"", ""}
      end

    compiler = @compilers |> Map.get(native.language)

    Unix.compiler_commands(
      native,
      "#{compiler} #{cflags}",
      "#{compiler} #{lflags}",
      native.language,
      native_interface,
      wrap_deps: &"-Wl,-all_load #{&1}"
    )
  end
end
