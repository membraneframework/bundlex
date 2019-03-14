defmodule Bundlex do
  @moduledoc """
  Some common utility functions.
  """

  alias Bundlex.Platform
  alias Bundlex.Helper.MixHelper

  @doc """
  Returns platform name passed by `--platform` command line argument or fallbacks
  to the current platform name.
  """
  @spec platform() :: :linux | :macosx | :windows32 | :windows64 | :android_armv7
  def platform() do
    Platform.get_from_opts!()
  end

  @doc """
  Returns family of the platform obtained with `platform/0`.
  """
  @spec family() :: :unix | :windows
  def family() do
    Platform.family(platform())
  end

  @doc """
  Returns path where compiled native is stored.
  """
  @spec build_path(application :: atom) :: String.t()
  def build_path(application \\ MixHelper.get_app!(), native) do
    Bundlex.Toolchain.output_path(application, native)
  end
end
