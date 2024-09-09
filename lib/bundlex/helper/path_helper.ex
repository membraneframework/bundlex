defmodule Bundlex.Helper.PathHelper do
  @moduledoc false
  # Module containing helper functions that ease traversing directories.

  @doc """
  Fixes slashes in the given path to match convention used on current
  operating system.

  Internally all elixir functions use slash as a path separator, even if
  running on windows, and it's not a bug but a feature (lol).

  See https://github.com/elixir-lang/elixir/issues/1236
  """
  @spec fix_slashes(String.t()) :: String.t()
  def fix_slashes(path) do
    case Bundlex.family() do
      :windows -> path |> String.replace("/", "\\")
      _family -> path
    end
  end
end
