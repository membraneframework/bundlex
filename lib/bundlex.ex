defmodule Bundlex do
  @moduledoc """
  Some common utility functions.
  """

  alias Bundlex.Platform
  alias Bundlex.Helper.MixHelper

  @doc """
  Returns current platform name.
  """
  @spec platform() :: :linux | :macosx | :windows32 | :windows64
  def platform() do
    Platform.get_current!()
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
