defmodule Bundlex.BuildScript do
  @moduledoc """
  Structure encapsulating build script generator.
  """

  alias Bundlex.Platform

  @script_ext unix: ".sh", windows: ".bat"
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

  @spec run(t, Platform.name_t()) :: :ok
  def run(%__MODULE__{} = bs, platform) do
    bs
    |> store_tmp(platform, fn script_name, script ->
      ret = "./#{script_name}" |> Mix.shell().cmd()

      if ret == 0 do
        :ok
      else
        {:error, {:run_build_script, return_code: ret, script: script}}
      end
    end)
  end

  @spec store(t, Platform.name_t(), String.t()) :: {:ok, {String.t(), String.t()}}
  def store(%__MODULE__{commands: commands}, platform, name \\ "bundlex") do
    family = platform |> family!()
    script_name = name <> @script_ext[family]
    script_prefix = @script_prefix[family]
    script = script_prefix <> (commands |> join_commands()) <> "\n"

    with :ok <- File.write(script_name, script),
         :ok <- if(family == :unix, do: File.chmod!(script_name, 0o755), else: :ok) do
      {:ok, {script_name, script}}
    end
  end

  @spec store_tmp(t, Platform.name_t(), (String.t(), String.t() -> x)) :: x | {:error, any}
        when x: {:ok, any} | {:error, any}
  def store_tmp(%__MODULE__{} = bs, platform, fun) do
    with {:ok, {script_name, script}} <- bs |> store(platform, "bundlex_tmp"),
         res = fun.(script_name, script),
         :ok <- File.rm(script_name) do
      res
    end
  end

  defp join_commands(commands) do
    commands
    |> Enum.map(&"(#{&1})")
    |> Enum.join(" && \\\n")
  end

  defp family!(:windows32), do: :windows
  defp family!(:windows64), do: :windows
  defp family!(:macosx), do: :unix
  defp family!(:linux), do: :unix
end
