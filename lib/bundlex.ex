defmodule Bundlex do
  alias __MODULE__.Platform

  @spec platform() :: Platform.name_t()
  @doc """
  Returns current platform name as atom
  """
  def platform() do
    Platform.get_current!()
  end
end
