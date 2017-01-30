defmodule Bundlex.Platform do
  @callback extra_otp_build_arguments() :: [] | [String.t]
  @callback extra_configure_options() :: [] | [String.t]
  @callback required_env_vars() :: [] | [String.t]
end
