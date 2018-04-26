defmodule Bundlex.BuildScript do
  @moduledoc """
  Structure encapsulating build script generator.
  """

  alias Bundlex.Output

  @script_name unix: "bundlex.sh", windows: "bundlex.bat"
  @script_prefix unix: "#!/bin/sh\n", windows: ""

  @type t :: %__MODULE__{
          commands: command_t
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

  @spec run!(t, Bundlex.Platform.platform_name_t()) :: :ok
  def run!(%__MODULE__{commands: commands}, platform) do
    family = platform |> family!()
    cmd = commands |> join_commands(family, :run)
    ret = cmd |> Mix.shell().cmd()

    if ret != 0 do
      Output.raise("Build script:\n\n#{cmd}\n\nreturned non-zero code: #{ret}")
    end

    :ok
  end

  @spec store!(t, Bundlex.Platform.platform_name_t()) :: {:ok, String.t()}
  def store!(%__MODULE__{commands: commands}, platform) do
    family = platform |> family!()
    script_name = @script_name[family]
    script_prefix = @script_prefix[family]
    script = script_prefix <> (commands |> join_commands(family, :store)) <> "\n"
    File.write!(script_name, script)
    if family == :unix, do: File.chmod!(script_name, 0o755)
    {:ok, script_name}
  end

  defp join_commands(commands, :unix, _) do
    commands
    |> Enum.map(&"(#{&1})")
    |> Enum.join(" && \\\n")
  end

  defp join_commands(commands, :windows, :run) do
    commands
    |> Enum.map(&"(#{&1})")
    |> Enum.join(" && ")
  end

  defp join_commands(commands, :windows, :store) do
    commands
    |> Enum.join("\n")
  end

  defp family!(:windows32), do: :windows
  defp family!(:windows64), do: :windows
  defp family!(:macosx), do: :unix
  defp family!(:linux), do: :unix
end
