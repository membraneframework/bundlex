defmodule Bundlex.Platform.Linux do
  @moduledoc false
  use Bundlex.Platform

  def toolchain_module() do
    Bundlex.Toolchain.GCC
  end
end
