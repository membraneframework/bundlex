defmodule Bundlex.Helper.ErlangHelper do
  @moduledoc """
  Module containing helper functions that ease determining path to locally-
  installed Erlang.
  """

  alias Bundlex.Helper.DirectoryHelper


  @doc """
  Tries to determine path to includes directory of locally installed Erlang.
  """
  @spec get_includes!(atom) :: String.t
  def get_includes!(:windows32), do: get_includes_windows!()
  def get_includes!(:windows64), do: get_includes_windows!()


  defp get_includes_windows! do
    # FIXME should be a wildcard
    case DirectoryHelper.wildcard("c:\\Program Files\\erl8.0\\erts-8.0") do
      nil ->
        Mix.raise "Unable to determine location of Erlang"

      directory ->
        Path.join(directory, "includes")
    end
  end
end
