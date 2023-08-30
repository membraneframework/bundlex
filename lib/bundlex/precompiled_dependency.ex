defmodule Bundlex.PrecompiledDependency do
  @typedoc """
  A type specyfing a module that implements #{inspect(__MODULE__)} behaviour.

  Such a module is used to describe the external repository with precompiled builds of given dependency.
  """
  @type t :: module()

  @typedoc """
  A tuple of three elements describing the platform.

  It consists of:
  * architecture - e.g. `x86_64` or `arm64`
  * vendor - e.g. `pc`
  * operating system - e.g. `linux` or `freebsd`
  """
  @type target_triplet ::
          {architecture :: String.t(), vendor :: String.t(), operating_system :: String.t()}

  @doc """
  A function returning the link to the compressed directory with the dependency build for a given target platform,
  or returning `:unavailable` atom, if such a link does not exist.
  """
  @callback get_build_url(target :: target_triplet) :: String.t() | :unavailable

  @doc """
  A function returning the path to the directory with dependency's header files, based on the
  path where the dependency has been unpacked, and the target platform.
  """
  @callback get_headers_path(unpacked_dependency_path :: String.t(), target :: target_triplet) ::
              String.t()

  @doc """
  A function returning the path to the directory with dependency's library files, based on the
  path where the dependency has been unpacked, and the target platform.
  """
  @callback get_libs_path(unpacked_dependency_path :: String.t(), target :: target_triplet) ::
              String.t()

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      @impl true
      def get_build_url(_target), do: :unavailable

      @impl true
      def get_headers_path(path, _target), do: "#{path}/include"

      @impl true
      def get_libs_path(path, _target), do: "#{path}/lib"

      defoverridable get_build_url: 1, get_headers_path: 2, get_libs_path: 2
    end
  end

  @doc """
  A function returning a target triplet for the environment on which it is run.
  """
  @spec get_target() :: target_triplet()
  def get_target() do
    [architecture, vendor, os | _rest] =
      :erlang.system_info(:system_architecture) |> List.to_string() |> String.split("-")

    {architecture, vendor, os}
  end
end
