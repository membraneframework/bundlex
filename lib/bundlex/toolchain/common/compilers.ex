defmodule Bundlex.Toolchain.Common.Compilers do
  @moduledoc """
  Provides few utilities related to various compilation methods
  """

  @enforce_keys [:c, :cpp]
  defstruct @enforce_keys

  def get_std_flag(:cpp) do
    "-std=c++17"
  end

  def get_std_flag(:c) do
    "-std=c11"
  end
end
