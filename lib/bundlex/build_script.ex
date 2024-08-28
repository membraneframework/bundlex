defmodule Bundlex.BuildScript do
  @moduledoc false

  use Bunch

  alias Bundlex.{Output, Platform}

  @script_ext unix: ".sh", windows: ".bat"
  @script_prefix unix: "#!/bin/sh\n", windows: "@echo off\r\n"

  @type t :: %__MODULE__{
          commands: [command_t]
        }

  @type command_t :: String.t()

  defstruct commands: []

  @doc """
  Creates new build script.
  """
  @spec new([command_t]) :: t
  def new(commands \\ []) do
    %__MODULE__{commands: commands}
  end

  @spec run(t, Platform.name_t()) ::
          :ok | {:error, {:run_build_script, return_code: integer, command: String.t()}}
  def run(script, platform)

  def run(%__MODULE__{commands: []}, _platform) do
    Output.warn("The list of commands is empty, did you forget to specify natives?")
  end

  def run(%__MODULE__{commands: commands}, platform) do
    family = Platform.family(platform)
    cmd = commands |> join_commands_run(family)

    case cmd |> Mix.shell().cmd() do
      0 -> :ok
      ret -> {:error, {:run_build_script, return_code: ret, command: cmd}}
    end
  end

  @spec store(t, Platform.name_t(), String.t()) :: {:ok, {String.t(), String.t()}}
  def store(%__MODULE__{commands: commands}, platform, name \\ "bundlex") do
    family = Platform.family(platform)
    script_name = name <> @script_ext[family]
    script_prefix = @script_prefix[family]
    script = script_prefix <> (commands |> join_commands(family))

    with :ok <- File.write(script_name, script),
         :ok <- if(family == :unix, do: File.chmod!(script_name, 0o755), else: :ok) do
      {:ok, {script_name, script}}
    end
  end

  # TODO: this is obviously awkward but I'm very tired.
  # should the toolchains define these?
  defp join_commands_run(commands, :windows) do
    Enum.join(commands, " && ")
  end

  defp join_commands_run(commands, family), do: join_commands(commands, family)

  defp join_commands(commands, :windows) do
    Enum.join(commands, "\r\n") <> "\r\n"
  end

  defp join_commands(commands, _other) do
    Enum.map_join(commands, " && \\\n", &"(#{&1})") <> "\n"
  end
end
