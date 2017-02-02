defmodule Bundlex.Makefile do
  @moduledoc """
  Structure encapsulating makefile generator.
  """


  @type t :: %Bundlex.Makefile{
    commands: String.t,
  }


  defstruct commands: ""


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
    %{makefile | commands: makefile.commands <> "\n" <> command}
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
end
