defmodule Bundlex.Toolchain.Nerves do
  @moduledoc false

  use Bundlex.Toolchain
  alias Bundlex.Native
  alias Bundlex.Toolchain.Common.Unix

  @impl Toolchain
  def compiler_commands(native) do
    {compiler, nerves_cflags} =
      case native.language do
        :c -> {System.fetch_env!("CC"), System.fetch_env!("CFLAGS")}
        :cpp -> {System.fetch_env!("CXX"), System.fetch_env!("CXXFLAGS")}
      end

    {cflags, lflags} =
      case native do
        %Native{type: :native, interface: :nif} ->
          {nerves_cflags <> " -fPIC", System.fetch_env!("LDFLAGS") <> " -rdynamic -shared"}

        %Native{type: :lib} ->
          {nerves_cflags <> " -fPIC", System.fetch_env!("LDFLAGS")}

        %Native{} ->
          {nerves_cflags, System.fetch_env!("LDFLAGS")}
      end

    Unix.compiler_commands(
      native,
      "#{compiler} #{cflags}",
      "#{compiler} #{lflags}",
      native.language,
      wrap_deps: &"-Wl,--disable-new-dtags,--whole-archive #{&1} -Wl,--no-whole-archive"
    )
  end
end
