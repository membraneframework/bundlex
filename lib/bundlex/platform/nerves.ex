defmodule Bundlex.Platform.Custom do
  @moduledoc false
  use Bundlex.Platform

  @impl true
  def toolchain_module() do
    Bundlex.Toolchain.Custom
  end
end
