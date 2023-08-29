defmodule Bundlex.PrecompiledDependency do
  @callback get_build_url(platform :: atom, target :: String.t()) :: String.t() | :unavailable

  @callback get_headers_path(path :: String.t(), platform :: atom, target :: String.t()) ::
              String.t()

  @callback get_libs_path(path :: String.t(), platform :: atom, target :: String.t()) ::
              String.t()

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      @impl true
      def get_headers_path(path, _platform, _target), do: "#{path}/include"

      @impl true
      def get_libs_path(path, _platform, _target), do: "#{path}/lib"

      defoverridable get_headers_path: 3, get_libs_path: 3
    end
  end
end
