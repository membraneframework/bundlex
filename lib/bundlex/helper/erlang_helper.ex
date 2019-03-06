defmodule Bundlex.Helper.ErlangHelper do
  @moduledoc """
  Module containing helper functions that ease determining path to locally-
  installed Erlang.
  """

  alias Bundlex.Platform

  @doc """
  Tries to determine paths to includes directory of locally installed Erlang.
  """
  @spec get_includes(Platform.name_t()) :: [String.t()]
  def get_includes(_platform) do
    [Path.join([:code.root_dir(), "usr", "include"])]
  end

  @doc """
  Tries to determine paths to libs directory of locally installed Erlang.
  """
  @spec get_lib_dirs(Platform.name_t()) :: [String.t()]
  def get_lib_dirs(_platform) do
    [Path.join([:code.root_dir(), "usr", "lib"])]
  end
end
