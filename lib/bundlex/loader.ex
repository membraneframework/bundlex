defmodule Bundlex.Loader do
  @moduledoc """
  Module containing functions that can be used to ease loading of Bundlex-based
  libraries.
  """

  alias Bundlex.Helper.DirectoryHelper

  defmacro __using__(args) do
    quote do
      import unquote(__MODULE__), only: [defnif: 1, defnifp: 1]
      @after_compile Bundlex.Loader
      @bundlex_nif_name unquote(args |> Keyword.fetch!(:nif))
      @bundlex_app_name unquote(args |> Keyword.get(:app))
      Module.register_attribute(__MODULE__, :bundlex_defnifs, accumulate: true)
    end
  end

  def __after_compile__(%{module: module} = env, _code) do
    funs = Module.delete_attribute(module, :bundlex_defnifs)
    nif_name = Module.delete_attribute(module, :bundlex_nif_name)
    app_name = Module.delete_attribute(module, :bundlex_app_name)

    defs =
      funs
      |> Enum.map(fn fun ->
        {name, _location, args} = fun

        args =
          args
          |> Enum.map(fn
            {:\\, _meta, [arg, _default]} -> arg
            arg -> arg
          end)

        quote do
          def unquote(fun) do
            raise "Nif fail: #{unquote(module)}.#{unquote(name)}/#{length(unquote(args))}"
          end
        end
      end)

    nif_module_content =
      quote do
        @moduledoc false
        require Bundlex.Loader
        @on_load :load_nif
        def load_nif() do
          Bundlex.Loader.load_nif!(unquote(app_name), unquote(nif_name))
        end

        unquote(defs)
      end

    Module.create(module |> Module.concat(Nif), nif_module_content, env)
  end

  defmacro defnif({name, _pos, args} = definition) do
    quote do
      @bundlex_defnifs unquote(Macro.escape(definition))
      @compile {:inline, [unquote({name, length(args)})]}
      defdelegate unquote(definition), to: __MODULE__.Nif
    end
  end

  defmacro defnifp({name, _pos, args} = definition) do
    quote do
      @bundlex_defnifs unquote(Macro.escape(definition))
      @compile {:inline, [unquote({name, length(args)})]}
      defp unquote(definition) do
        __MODULE__.Nif.unquote(definition)
      end
    end
  end

  @doc """
  Loads NIF for given app_name and given name.
  Second argument has to be an atom, the same as name of the NIF in the bundlex
  project.
  """
  @spec load_nif!(atom, atom) :: any
  defmacro load_nif!(app_name \\ nil, nif_name) do
    quote do
      app_name =
        unquote(
          app_name || Application.get_application(__MODULE__) ||
            Bundlex.Helper.MixHelper.get_app!()
        )

      nif_name = unquote(nif_name)

      path = Bundlex.Toolchain.output_path(app_name, nif_name)

      with :ok <- :erlang.load_nif(path |> DirectoryHelper.fix_slashes() |> to_charlist(), 0) do
        :ok
      else
        {:error, {reason, text}} ->
          raise """
          Bundlex cannot load nif #{inspect(nif_name)} of app #{inspect(app_name)}
          from "#{path}", check bundlex.exs file for information about nifs.
          Reason: #{inspect(reason)}, #{to_string(text)}
          """
      end
    end
  end
end
