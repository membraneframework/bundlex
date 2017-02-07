defmodule Bundlex.Loader do
  @moduledoc """
  Module containing functions that can be used to ease loading of Bundlex-based
  libraries.
  """


  @doc """
  Loads NIF for given app_name and given name.

  This aims to be a workadound for https://github.com/elixir-lang/elixir/issues/5746

  First argument has to be an atom, the same as `:app` in the `mix.exs` of the
  library. It is used to retreive real path of the dependency on the hard drive.

  Second argument has to be an atom, the same as name of the NIF in the bundlex
  library config.
  """
  @spec load_lib_nif!(atom, atom) :: any
  defmacro load_lib_nif!(app_name, nif_name) do
    quote do
      app_name = unquote(app_name)
      nif_name = unquote(nif_name)

      path = case Mix.Project.deps_paths[app_name] do
        nil ->
          "./#{nif_name}"

        dependency_path ->
          "#{dependency_path}/#{nif_name}"
      end

      :ok = :erlang.load_nif(path |> to_charlist(), 0)
    end
  end
end
