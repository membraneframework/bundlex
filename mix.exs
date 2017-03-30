defmodule Bundlex.Mixfile do
  use Mix.Project

  def project do
    [app: :bundlex,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "Bundlex Multi-Platform build system for Elixir",
     maintainers: ["Marcin Lewandowski"],
     licenses: ["Proprietary"],
     name: "Bundlex",
     source_url: "https://github.com/radiokit/bundlex",
     preferred_cli_env: [espec: :test],
     deps: [{:porcelain, "~> 2.0"}]]
  end


  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib",]
end
