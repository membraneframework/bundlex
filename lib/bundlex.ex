defmodule Bundlex do
  @doc """
  Returns list of Mix-compatible compilers for compiling libraries.

  Sample usage will invoke passing it to the `:compilers` key in your project
  config in library's `mix.exs`:

      def project do
        [app: :sample_lib,
         compilers: Bundlex.lib_compilers ++ Mix.compilers,
         version: "0.0.1",
         elixir: "~> 1.3",
         elixirc_paths: elixirc_paths(Mix.env),
         description: "Sample Lib",
         maintainers: ["John Smith"],
         licenses: ["LGPL"],
         name: "Sample",
         source_url: "https://github.com/sample/lib",
         deps: []]
      end
  """
  @spec lib_compilers :: [String.t]
  def lib_compilers do
    ~w(bundlex.lib)
  end
end
