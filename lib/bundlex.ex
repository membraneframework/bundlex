defmodule Bundlex do
  @moduledoc """
  Some common utility functions.
  """

  alias Bundlex.Helper.MixHelper
  alias Bundlex.Platform

  @type platform_t :: :linux | :macosx | :windows32 | :windows64 | :nerves | :custom

  @typedoc """
  A map containing four fields that describe the platform.

  It consists of:
  * architecture - e.g. `x86_64` or `arm64`
  * vendor - e.g. `pc`
  * os - operating system, e.g. `linux` or `darwin20.6.0`
  * abi - application binary interface, e.g. `musl` or `gnu`
  """
  @type target ::
          %{
            architecture: String.t() | :unknown,
            vendor: String.t() | :unknown,
            os: String.t() | :unknown,
            abi: String.t() | :unknown
          }

  @doc """
  A function returning information about the target platform (unknown in case of crosscompilation).
  """
  @spec get_target() :: target()
  if Mix.target() == :host do
    def get_target() do
      [architecture, vendor, os | maybe_abi] =
        :erlang.system_info(:system_architecture) |> List.to_string() |> String.split("-")

      %{
        architecture: architecture,
        vendor: vendor,
        os: os,
        abi: List.first(maybe_abi) || :unknown
      }
    end
  else
    def get_target() do
      %{
        architecture: :unknown,
        vendor: :unknown,
        os: :unknown,
        abi: :unknown
      }
    end
  end

  @doc """
  Returns current platform name.
  """
  @spec platform() :: platform_t()
  def platform() do
    Platform.get_target!()
  end

  @doc """
  Returns family of the platform obtained with `platform/0`.
  """
  @spec family() :: :unix | :windows | :custom
  def family() do
    Platform.family(platform())
  end

  @doc """
  Returns path where compiled native is stored.
  """
  @spec build_path(application :: atom, native :: atom, native_interface :: atom) :: String.t()
  def build_path(application \\ MixHelper.get_app!(), native, native_interface) do
    Bundlex.Toolchain.output_path(application, native, native_interface)
  end
end
