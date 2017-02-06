defmodule Bundlex.Makefile do
  @moduledoc """
  Structure encapsulating makefile generator.
  """


  @type t :: %Bundlex.Makefile{
    commands: String.t,
  }


  defstruct commands: []


  @doc """
  Creates new makefile.
  """
  @spec new() :: t
  def new() do
    struct(__MODULE__)
  end


  @doc """
  Appends single command to the makefile.
  """
  @spec append_command!(t, String.t) :: t
  def append_command!(makefile, command) do
    %{makefile | commands: makefile.commands ++ [command]}
  end


  @doc """
  Appends many commands to the makefile.
  """
  @spec append_commands!(t, [] | [String.t]) :: t
  def append_commands!(makefile, commands) do
    Enum.reduce(commands, makefile, fn(item, acc) ->
      append_command!(acc, item)
    end)
  end


  @spec save!(t, Bundlex.Platform.platform_name_t) :: :ok
  def save!(makefile, :windows32), do: save_windows!(makefile)
  def save!(makefile, :windows64), do: save_windows!(makefile)


  defp save_windows!(makefile) do
    content = "@echo off\nREM This is Bundlex makefile generated automatically at #{DateTime.utc_now |> to_string}\n\n"

    content = makefile.commands
    |> Enum.reduce(content, fn(item, acc) ->
      acc <> item <> "\n"
    end)

    File.write!("bundlex.bat", content)
  end
end
