defmodule Bundlex.Toolchain do
  @doc """
  Invokes commands that should be called before whole compilation process
  for given platform.

  Implementations should call `Output.raise/1` in case of failure which will
  cause breaking the compilation process.

  In case of success implementations should return list of commands to be
  called upon compilation.

  Default implentation do nothing.
  """
  @callback before_all!(atom) :: [] | [String.t()]

  @doc """
  Builds list of compiler commands valid for certain toolchain.

  It will receive includes, libs, sources, pkg_configs, nif_name.
  """
  @callback compiler_commands(Bundlex.NIF.t(), app_name :: atom, nif_name :: atom) :: [String.t()]

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)
      alias unquote(__MODULE__)

      # Default implementations

      @doc false
      def before_all!(_platform), do: []

      defoverridable before_all!: 1
    end
  end

  def output_path(app_name) do
    [Mix.Project.build_path(), "lib", "#{app_name}", "priv", "bundlex"] |> Path.join()
  end

  def output_path(app_name, nif_name) do
    output_path(app_name) |> Path.join("#{nif_name}")
  end
end
