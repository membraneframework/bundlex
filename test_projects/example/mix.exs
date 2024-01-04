defmodule Example.MixProject do
  use Mix.Project

  @bundlex_path System.fetch_env!("BUNDLEX_PATH")

  def project do
    [
      app: :example,
      version: "0.1.0",
      elixir: "~> 1.10",
      compilers: if(System.get_env("BUNDLEX_FORCE_NO_COMPILE"), do: [], else: [:bundlex]) ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps_path: "#{@bundlex_path}/deps",
      lockfile: "#{@bundlex_path}/mix.lock",
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bundlex, path: @bundlex_path},
      {:example_lib, path: "../example_lib"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "pages/doxygen/example.md"
      ]
    ]
  end
end
