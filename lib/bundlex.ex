defmodule Bundlex do
  @moduledoc """
  Some common utility functions.
  """

  alias Bundlex.Helper.MixHelper
  alias Bundlex.Platform

  @type platform_t :: :linux | :macosx | :windows32 | :windows64 | :nerves | :custom

  @typedoc """
  A map containing four fields that describe the target platform.

  It consists of:
  * architecture - e.g. `x86_64` or `arm64`
  * vendor - e.g. `pc`
  * os - operating system, e.g. `linux` or `darwin20.6.0`
  * abi - application binary interface, e.g. `musl` or `gnu`
  """
  @type target ::
          %{
            architecture: String.t(),
            vendor: String.t(),
            os: String.t(),
            abi: String.t()
          }

  @doc """
  A function returning information about the target platform. In case of cross-compilation the
  information can be provided by setting appropriate environment variables.
  """
  @spec get_target() :: target()
  case System.fetch_env("CROSSCOMPILE") do
    :error ->
      def get_target() do
        [architecture, vendor, os | maybe_abi] =
          :erlang.system_info(:system_architecture) |> List.to_string() |> String.split("-")

        %{
          architecture: architecture,
          vendor: vendor,
          os: os,
          abi: List.first(maybe_abi) || "unknown"
        }
      end

    {:ok, _} ->
      target = 
        Map.new(
          [
            {:architecture, "TARGET_ARCH"},
            {:vendor, "TARGET_VENDOR"},
            {:os, "TARGET_OS"},
            {:abi, "TARGET_ABI"}
          ],
          fn {key, env} ->
            value =
              case System.fetch_env(env) do
                {:ok, value} -> value
                :error -> "unknown"
              end

            {key, value}
          end
        )
      def get_target() do
        unquote(target)
      end
  end

  @doc """
  Returns current platform name.
  """
  @deprecated "Use Bundlex.get_target/0 instead"
  @spec platform() :: platform_t()
  def platform() do
    case Platform.get_target!() do
      :custom -> :nerves
      platform -> platform
    end
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
