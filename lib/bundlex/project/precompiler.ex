defmodule Bundlex.Project.Precompiler do
  alias Bundlex.Project

  @callback precompile_native_config(name :: atom, app :: atom, Project.native_config_t()) ::
              Project.native_config_t()
  @callback precompile_native(Native.t()) :: Native.t()
end
