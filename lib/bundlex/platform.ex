defmodule Bundlex.Platform do
  @moduledoc false
  alias Bundlex.Output

  @type name_t :: atom
  @type family_name_t :: atom

  @callback extra_otp_configure_options() :: [] | [String.t()]
  @callback required_env_vars() :: [] | [String.t()]
  @callback patches_to_apply() :: [] | [String.t()]
  @callback toolchain_module() :: module

  defmacro __using__(_args) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def extra_otp_configure_options() do
        []
      end

      @impl unquote(__MODULE__)
      def required_env_vars() do
        []
      end

      @impl unquote(__MODULE__)
      def patches_to_apply() do
        []
      end

      defoverridable unquote(__MODULE__)
    end
  end

  @doc """
  Detects target platform.

  In case of success returns platform name

  Otherwise raises Mix error.
  """
  @spec get_target!() :: name_t

  case System.fetch_env("CROSSCOMPILE") do
    :error ->
      def get_target!() do
        case :os.type() do
          {:win32, _} ->
            {:ok, reg} = :win32reg.open([:read])

            :ok =
              :win32reg.change_key(
                reg,
                ~c"\\hklm\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion"
              )

            {:ok, build} = :win32reg.value(reg, ~c"BuildLabEx")

            platform_name =
              if build |> to_string |> String.contains?("amd64") do
                :windows64
              else
                :windows32
              end

            :ok = :win32reg.close(reg)

            platform_name

          {:unix, :linux} ->
            :linux

          {:unix, :freebsd} ->
            :freebsd

          {:unix, :darwin} ->
            :macosx

          other ->
            # TODO add detection for more platforms
            Output.raise(
              "Unable to detect current platform. Erlang returned #{inspect(other)} which I don't know how to handle."
            )
        end
      end

    {:ok, _crosscompile} ->
      case System.fetch_env("NERVES_APP") do
        {:ok, _app} ->
          def get_target!(), do: :nerves

        :error ->
          Output.info(
            "Cross-compiling without using Nerves. Make sure necessary environment variables are set correctly."
          )

          def get_target!(), do: :custom
      end
  end

  @spec family(name_t) :: family_name_t
  def family(:windows32), do: :windows
  def family(:windows64), do: :windows
  def family(:linux), do: :unix
  def family(:macosx), do: :unix
  def family(:freebsd), do: :unix
  def family(:nerves), do: :unix
  def family(:custom), do: :custom

  @spec get_module(family_name_t) :: module
  def get_module(:windows32), do: Bundlex.Platform.Windows32
  def get_module(:windows64), do: Bundlex.Platform.Windows64
  def get_module(:macosx), do: Bundlex.Platform.MacOSX
  def get_module(:linux), do: Bundlex.Platform.Linux
  def get_module(:freebsd), do: Bundlex.Platform.Freebsd
  def get_module(:nerves), do: Bundlex.Platform.Custom
  def get_module(:custom), do: Bundlex.Platform.Custom
end
