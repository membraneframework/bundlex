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

  def get_includes!(:macosx) do
    # Assumes that user has erlang installed via brew
    Bundlex.Helper.DirectoryHelper.wildcard("/usr/local/Cellar/erlang/*/lib/erlang/usr/include/")
  end

  def get_includes!(:linux) do
    # FIXME
    Bundlex.Helper.DirectoryHelper.wildcard("/usr/local/erlang/usr/include/")
  end


  defp get_includes_windows! do
    # FIXME should be a wildcard
    case DirectoryHelper.wildcard("c:\\Program Files\\erl8.3\\erts-8.3\\include") do
      nil ->
        Mix.raise "Unable to determine location of Erlang include dir (do you have Erlang 19.0 installed?)"

      directory ->
        directory
    end
  end
end
