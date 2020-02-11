defmodule Bundlex.Port do
    alias Bundlex.Helper.MixHelper

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