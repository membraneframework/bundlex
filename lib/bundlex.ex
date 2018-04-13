defmodule Bundlex do
  def platform() do
    Bundlex.Platform.get_current_platform!()
  end
end
