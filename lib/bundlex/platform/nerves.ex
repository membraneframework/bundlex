defmodule Bundlex.Platform.Nerves do
  @moduledoc false
  use Bundlex.Platform

  @impl true
  def toolchain_module() do
    Bundlex.Toolchain.Nerves
  end
end
