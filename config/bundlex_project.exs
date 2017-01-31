use Mix.Config

config :bundlex_project, :windows32,
  erlang_version: "18.3.4",
  erlang_disabled_apps: ~w(wx),
  elixir_version: "1.3.4"

config :bundlex_project, :windows64,
  erlang_version: "18.3.4",
  erlang_disabled_apps: ~w(wx),
  elixir_version: "1.3.4"

config :bundlex_project, :unix64,
  erlang_version: "19.2.1",
  erlang_disabled_apps: ~w(wx),
  elixir_version: "1.4.1"

config :bundlex_project, :android_armv7,
  erlang_version: "19.2.1",
  erlang_disabled_apps: ~w(wx),
  elixir_version: "1.4.1",
  android_api_version: "21"

# asn1 common_test cosEvent cosEventDomain cosFileTransfer cosNotification cosProperty cosTime cosTransactions crypto debugger dialyzer diameter edoc eldap erl_docgen erl_interface et eunit gs hipe ic inets jinterface megaco mnesia observer odbc orber os_mon otp_mibs parsetools percept public_key reltool runtime_tools sasl snmp ssh ssl syntax_tools tools typer wx xmerl