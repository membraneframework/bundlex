use Mix.Config

config :bundlex, :windows32,
  erlang_version: "18.3.4",
  erlang_disabled_apps: ~w(wx),
  elixir_version: "1.3.4"


config :bundlex, :windows64,
  erlang_version: "18.3.4",
  erlang_disabled_apps: ~w(wx),
  elixir_version: "1.3.4"
