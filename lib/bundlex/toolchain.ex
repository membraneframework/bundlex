defmodule Bundlex.Toolchain do
  @doc """
  Invokes commands that should be called before whole compilation process
  for given platform.

  Implementations should call `Output.raise/1` in case of failure which will
  cause breaking the compilation process.

  In case of success implementations should return list of commands to be
  called upon compilation.

  Default implentation does nothing.
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

  def output_path(app_name) do
    # It seems that we have two methods to determine where Natives are located:
    # * `Mix.Project.build_path/0`
    # * `:code.priv_dir/1`
    #
    # Both seem to be unreliable, at least in Elixir 1.7:
    #
    # * we cannot call `Mix.Project.build_path/0` from `@on_load` handler as
    #   there are race conditions and it seems that some processes from the
    #   `:mix` app are not launched yet (yes, we tried to ensure that `:mix`
    #   app is started, calling `Application.ensure_all_started(:mix)` prior
    #   to calling `Mix.Project.build_path/0` causes deadlock; calling it
    #   without ensuring that app is started terminates the whole app; adding
    #   `:mix` to bundlex OTP applications does not seem to help either),
    # * it seems that when using releases, `Mix.Project.build_path/0` returns
    #   different results in compile time and run time,
    # * moreover, it seems that the paths returned by `Mix.Project.build_path/0`
    #   when using releases and `prod` env might have a `dev` suffix unless
    #   a developer remembers to disable `:build_per_environment: setting,
    # * `:code.priv_dir/1` is not accessible in the compile time, but at least
    #   it does not crash anything.
    #
    # As a result, we try to call `:code.priv_dir/1` first, and if it fails,
    # we are probably in the build time and need to fall back to
    # `Mix.Project.build_path/0`. Previously the check was reversed and it
    # caused crashes at least when using distillery >= 2.0 and Elixir 1.7.
    #
    # Think twice before you're going to be another person who spent many
    # hours on trying to figure out why such simple thing as determining
    # a path might be so hard.
    case :code.priv_dir(app_name) do
      {:error, :bad_name} ->
        [Mix.Project.build_path(), "lib", "#{app_name}", "priv", "bundlex"] |> Path.join()

      path ->
        [path, "bundlex"] |> Path.join()
    end
  end

  def output_path(app_name, nif_name) do
    output_path(app_name) |> Path.join("#{nif_name}")
  end
end
