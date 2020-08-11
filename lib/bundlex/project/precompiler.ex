defmodule Bundlex.Project.Precompiler do
  @moduledoc """
  Behaviour for precompiling Bundlex projects.

  Precompiling may involve either generating additional resources or altering the project itself.
  Currently, precompiling native configuration (`c:precompile_native_config/3`)
  and parsed natives (`c:precompile_native/1`) is supported.
  """
  alias Bundlex.{Native, Project}

  @type t :: module

  @callback precompile_native_config(
              name :: atom,
              app :: atom,
              config :: Project.native_config_t()
            ) ::
              Project.native_config_t()
  @callback precompile_native(native :: Native.t()) :: Native.t()
end
