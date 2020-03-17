defmodule Bundlex.Port do
  @moduledoc """
  Utilities to ease interaction with Ports
  """
  alias Bundlex.Helper.MixHelper

  @doc """
  Spawns Port `native_name` from application of calling module.
  """
  defmacro open(native_name, args \\ []) do
    app = MixHelper.get_app!(__CALLER__.module)

    quote do
      unquote(__MODULE__).open(unquote(app), unquote(native_name), unquote(args))
    end
  end

  def open(app, native_name, args) do
    Port.open(
      {:spawn_executable, Bundlex.build_path(app, native_name)},
      args: args
    )
  end
end
