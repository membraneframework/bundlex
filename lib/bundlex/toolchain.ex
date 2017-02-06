defmodule Bundlex.Toolchain do
  @doc """
  Invokes commands that should be called before whole compilation process
  for given platform.

  Implementations should call `Mix.raise/1` in case of failure which will
  cause breaking the compilation process.

  In case of success implementations should return list of commands to be
  called upon compilation.

  Default implentation do nothing.
  """
  @callback before_all!(atom) :: [] | [String.t]



  @doc """
  Builds list of compiler commands valid for certain toolchain.
  """
  @callback compiler_commands([String.t], [String.t], [String.t], String.t) :: [String.t]



  @doc """
  Builds list of post-build commands copying output files to right locations
  valid for certain toolchain.
  """
  @callback post_copy_commands(String.t) :: [String.t]


  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Bundlex.Toolchain


      # Default implementations

      @doc false
      def before_all!(_platform), do: []


      defoverridable [
        before_all!: 1,
      ]
    end
  end
end
