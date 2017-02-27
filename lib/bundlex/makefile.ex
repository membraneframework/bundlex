defmodule Bundlex.Makefile do
  @moduledoc """
  Structure encapsulating makefile generator.
  """

  @windows_script_name "bundlex.bat"
  @unix_script_name "bundlex.sh"

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


  @spec run!(t, Bundlex.Platform.platform_name_t) :: :ok
  def run!(makefile, :windows32), do: run_windows!(makefile)
  def run!(makefile, :windows64), do: run_windows!(makefile)
  def run!(makefile, :macosx), do: run_unix!(makefile)
  def run!(makefile, :linux), do: run_unix!(makefile)


  defp run_windows!(makefile) do
    content = makefile.commands
    |> Enum.reduce("", fn(item, acc) ->
      # TODO check errorlevel

      case item do
        {command, label} ->
          acc <> "echo #{label}\n" <> item <> "\n"

        command ->
          acc <> item <> "\n"
      end
    end)


    File.write!(@windows_script_name, content)

    case Mix.shell.cmd(@windows_script_name, stderr_to_stdout: true) do
      0 ->
        # FIXME
        # File.rm!(@windows_script_name)
        Bundlex.Output.info3 "Build script finished gracefully"

      other ->
        # FIXME
        # File.rm!(@windows_script_name)
        Mix.raise "Build script finished with error code #{other}"
    end
  end


  defp run_unix!(makefile) do
    content = makefile.commands
    |> Enum.reduce("#!/bin/sh\n", fn(item, acc) ->
      case item do
        {command, label} ->
          acc <> "echo #{label}\n" <> item <> "\n"

        command ->
          acc <> item <> "\n"
      end
    end)


    File.write!(@unix_script_name, content)
    File.chmod!(@unix_script_name, 0o755)

    case Mix.shell.cmd("./#{@unix_script_name}", stderr_to_stdout: true) do
      0 ->
        # FIXME
        # File.rm!(@windows_script_name)
        Bundlex.Output.info3 "Build script finished gracefully"

      other ->
        # FIXME
        # File.rm!(@windows_script_name)
        Mix.raise "Build script finished with error code #{other}"
    end
  end
end
