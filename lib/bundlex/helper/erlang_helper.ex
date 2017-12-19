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
  def get_includes!(_platform), do: Path.join [:code.root_dir, "usr", "include"]

end
