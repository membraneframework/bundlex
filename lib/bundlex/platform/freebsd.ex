defmodule Bundlex.Platform.Freebsd do
  @moduledoc false
  use Bundlex.Platform

  def toolchain_module() do
    Bundlex.Toolchain.GCC
  end
end
