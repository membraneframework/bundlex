defmodule Bundlex.Platform.Windows32 do
  @moduledoc false
  use Bundlex.Platform

  def toolchain_module() do
    Bundlex.Toolchain.VisualStudio
  end
end
