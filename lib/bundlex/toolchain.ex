defmodule Bundlex.Toolchain do
  @moduledoc false

  alias Bundlex.Helper.MixHelper
  alias Bundlex.Project

  @doc """
  Invokes commands that should be called before whole compilation process
  for given platform.

  Implementations should call `Output.raise/1` in case of failure which will
  cause breaking the compilation process.

  In case of success implementations should return list of commands to be
  called upon compilation.

  Default implementation does nothing.
  """
  @callback before_all!(atom) :: [] | [String.t()]

  @doc """
  Builds list of compiler commands valid for certain toolchain.
  """
  @callback compiler_commands(Bundlex.Native.t()) :: [String.t()]

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
      alias unquote(__MODULE__)

      # Default implementations

      @impl unquote(__MODULE__)
      def before_all!(_platform), do: []

      defoverridable before_all!: 1
    end
  end

  @spec output_path(Application.app(), Project.native_interface()) :: Path.t()
  def output_path(app, native_interface) do
    interface_str =
      case native_interface do
        nil -> ""
        interface -> "#{interface}"
      end

    MixHelper.get_priv_dir(app) |> Path.join("bundlex") |> Path.join(interface_str)
  end

  @spec output_path(Application.app(), Project.native_name(), Project.native_interface()) ::
          Path.t()
  def output_path(app, native_name, native_interface) do
    output_path(app, native_interface) |> Path.join("#{native_name}")
  end

  @spec bundlex_shared_path() :: Path.t()
  def bundlex_shared_path() do
    Path.join(MixHelper.get_priv_dir(:bundlex), "shared")
  end
end
