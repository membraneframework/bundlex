defmodule Bundlex.Mixfile do
  use Mix.Project

  @github_url "https://github.com/membraneframework/bundlex"

  def project do
    [
      app: :bundlex,
      version: "0.1.2",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Bundlex Multi-Platform build system for Elixir",
      package: package(),
      name: "Bundlex",
      source_url: @github_url,
      docs: docs(),
      preferred_cli_env: [espec: :test],
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  defp deps() do
    Application.put_env(:porcelain, :driver, Porcelain.Driver.Basic)

    [
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:porcelain, "~> 2.0"}
    ]
  end
end
