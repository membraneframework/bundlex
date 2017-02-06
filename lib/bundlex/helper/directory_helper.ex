defmodule Bundlex.Helper.DirectoryHelper do
  @moduledoc """
  Module containing helper functions that ease traversing directories.
  """


  @doc """
  Tries to find a directory that matches given pattern that has the biggest
  version number if it is expected to be a suffix.
  """
  @spec wildcard(String.t) :: nil | String.t
  def wildcard(pattern) do
    directory = Path.wildcard(pattern)
      |> Enum.sort
      |> List.last

    case directory do
      nil ->
        nil

      directory ->
        directory
    end
  end
end
