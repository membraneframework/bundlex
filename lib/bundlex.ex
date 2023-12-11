defmodule Bundlex do
  @moduledoc """
  Some common utility functions.
  """

  alias Bundlex.Helper.MixHelper
  alias Bundlex.Platform

  @type platform_t :: :linux | :macosx | :windows32 | :windows64 | :nerves

  @typedoc """
  A map containing four fields that describe the platform.

  It consists of:
  * architecture - e.g. `x86_64` or `arm64`
  * vendor - e.g. `pc`
  * os - operating system, e.g. `linux` or `darwin20.6.0`
  * abi (optional) - application binary interface, e.g. `musl` or `gnu`
  """
  @type target ::
          %{architecture: String.t(), vendor: String.t(), os: String.t(), abi: String.t() | nil}
  @doc """
  A function returning a target triplet for the environment on which it is run.
  """
  @spec get_target() :: target()
  def get_target() do
    [architecture, vendor, os | maybe_abi] =
      :erlang.system_info(:system_architecture) |> List.to_string() |> String.split("-")

    %{
      architecture: architecture,
      vendor: vendor,
      os: os,
      abi: List.first(maybe_abi)
    }
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
  @spec family() :: :unix | :windows
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

  @spec default_os_dep_config(os_dep_name :: atom()) :: Bundlex.Project.os_dep()
  def default_os_dep_config(os_dep_name) do
    precompiled_package_url_prefix =
      "https://github.com/membraneframework-precompiled/precompiled_#{os_dep_name}/releases/latest/download/#{os_dep_name}"

    precompiled_package_url =
      case Bundlex.get_target() do
        %{os: "linux", vendor: "alpine"} ->
          nil

        %{os: "linux"} ->
          "#{precompiled_package_url_prefix}_linux.tar.gz"

        %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
          "#{precompiled_package_url_prefix}_macos_intel.tar.gz"

        %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
          "#{precompiled_package_url_prefix}_macos_arm.tar.gz"

        _other ->
          nil
      end

    if precompiled_package_url != nil do
      {os_dep_name, [{:precompiled, precompiled_package_url}, :pkg_config]}
    else
      {os_dep_name, [:pkg_config]}
    end
  end
end
