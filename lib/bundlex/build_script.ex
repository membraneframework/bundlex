defmodule Bundlex.BuildScript do
  @moduledoc false

  alias Bundlex.Platform
  use Bunch

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
  def run(%__MODULE__{commands: commands}, platform) do
    family = platform |> family!()
    cmd = commands |> join_commands(family)

    case cmd |> Mix.shell().cmd() do
      0 -> :ok
      ret -> {:error, {:run_build_script, return_code: ret, command: cmd}}
    end
  end

  @spec store(t, Platform.name_t(), String.t()) :: {:ok, {String.t(), String.t()}}
  def store(%__MODULE__{commands: commands}, platform, name \\ "bundlex") do
    family = platform |> family!()
    script_name = name <> @script_ext[family]
    script_prefix = @script_prefix[family]
    script = script_prefix <> (commands |> join_commands(family))

    with :ok <- File.write(script_name, script),
         :ok <- if(family == :unix, do: File.chmod!(script_name, 0o755), else: :ok) do
      {:ok, {script_name, script}}
    end
  end

  defp join_commands(commands, :unix) do
    commands
    |> Enum.map(&"(#{&1})")
    |> Enum.join(" && \\\n")
    ~> (&1 <> "\n")
  end

  defp join_commands(commands, :windows) do
    commands
    |> Enum.join("\r\n")
    ~> (&1 <> "\r\n")
  end

  defp family!(:windows32), do: :windows
  defp family!(:windows64), do: :windows
  defp family!(:macosx), do: :unix
  defp family!(:linux), do: :unix
end
