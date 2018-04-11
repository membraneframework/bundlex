defmodule Bundlex.Makefile do
  @moduledoc """
  Structure encapsulating makefile generator.
  """

  @windows_script_name "bundlex.bat"
  @unix_script_name "bundlex.sh"

  @type t :: %__MODULE__{
    commands: command_t
  }

  @type command_t :: String.t


  defstruct commands: []


  @doc """
  Creates new makefile.
  """
  @spec new([command_t]) :: t
  def new(commands \\ []) do
    %__MODULE__{commands: commands}
  end


  @spec run!(t, Bundlex.Platform.platform_name_t) :: :ok
  def run!(makefile, :windows32), do: do_run!(makefile, :windows)
  def run!(makefile, :windows64), do: do_run!(makefile, :windows)
  def run!(makefile, :macosx), do: do_run!(makefile, :unix)
  def run!(makefile, :linux), do: do_run!(makefile, :unix)


  defp do_run!(%__MODULE__{commands: commands}, family) do
    commands
    |> Enum.each(fn cmd ->
        ret = cmd |> Mix.shell.cmd
        if ret != 0 do
          Mix.raise("Command #{cmd} returned non-zero code: #{ret}")
        end
      end)
  end
  #
  # defp run_windows!(makefile) do
  #   content = makefile.commands
  #   |> Enum.reduce("", fn(item, acc) ->
  #     # TODO check errorlevel
  #
  #     case item do
  #       {command, label} ->
  #         acc <> "echo #{label}\n" <> item <> "\n"
  #
  #       command ->
  #         acc <> item <> "\n"
  #     end
  #   end)
  #
  #
  #   File.write!(@windows_script_name, content)
  #
  #   case Mix.shell.cmd(@windows_script_name, stderr_to_stdout: true) do
  #     0 ->
  #       # FIXME
  #       # File.rm!(@windows_script_name)
  #       Bundlex.Output.info_substage "Build script finished gracefully"
  #
  #     other ->
  #       # FIXME
  #       # File.rm!(@windows_script_name)
  #       Mix.raise "Build script finished with error code #{other}"
  #   end
  # end
  #
  #
  # defp run_unix!(makefile) do
  #   content = makefile.commands
  #   |> Enum.reduce("#!/bin/sh\n", fn(item, acc) ->
  #     case item do
  #       {command, label} ->
  #         acc <> "echo #{label}\n" <> item <> "\n"
  #
  #       command ->
  #         acc <> item <> "\n"
  #     end
  #   end)
  #
  #
  #   File.write!(@unix_script_name, content)
  #   File.chmod!(@unix_script_name, 0o755)
  #
  #   case Mix.shell.cmd("./#{@unix_script_name}", stderr_to_stdout: true) do
  #     0 ->
  #       # FIXME
  #       # File.rm!(@windows_script_name)
  #       Bundlex.Output.info_substage "Build script finished gracefully"
  #
  #     other ->
  #       # FIXME
  #       # File.rm!(@windows_script_name)
  #       Mix.raise "Build script finished with error code #{other}"
  #   end
  # end
end
