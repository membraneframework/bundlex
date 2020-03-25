defmodule Bundlex.Toolchain.Common.Compilers do
  @moduledoc false
  #  Provides few utilities related to various compilation methods

  @enforce_keys [:c, :cpp]
  defstruct @enforce_keys

  @doc """
  Provides compiler flag specyfying language standard, each one for every supported language
  """
  @spec get_std_flag(atom) :: String.t()
  def get_std_flag(:cpp) do
    "-std=c++17"
  end

  def get_std_flag(:c) do
    "-std=c11"
  end
end
