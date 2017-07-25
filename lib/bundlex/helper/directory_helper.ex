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


  @doc """
  Fixes slashes in the given path to match convention used on current
  operating system.

  Internally all elixir functions use slash as a path separator, even if
  running on windows, and it's not a bug but a feature (lol).
  
  See https://github.com/elixir-lang/elixir/issues/1236
  """
  @spec fix_slashes(String.t) :: String.t
  def fix_slashes(path) do
    case :os.type do
      {:win32, _} ->
        path |> String.replace("/", "\\")

      _ ->
        path
    end
  end
end
