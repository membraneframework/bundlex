defmodule Bundlex.Toolchain.GCC do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Toolchain.Common.{Unix, Compilers}

  @compilers %Compilers{c: "gcc", cpp: "g++"}

  @impl Toolchain
  def compiler_commands(native, native_interface \\ nil) do
    {cflags, lflags} =
      case native.type do
        :native ->
          if :nif in native.interfaces do
            {"-fPIC", "-rdynamic -shared"}
          else
            {"", ""}
          end

        :nif ->
          {"-fPIC", "-rdynamic -shared"}

        :lib ->
          {"-fPIC", ""}

        _ ->
          {"", ""}
      end

    compiler = @compilers |> Map.get(native.language)

    Unix.compiler_commands(
      native,
      "#{compiler} #{cflags}",
      "#{compiler} #{lflags}",
      native.language,
      native_interface,
      wrap_deps: &"-Wl,--whole-archive #{&1} -Wl,--no-whole-archive"
    )
  end
end
