defmodule Bundlex.Platform do
  @callback extra_otp_configure_options() :: [] | [String.t]
  @callback required_env_vars() :: [] | [String.t]
  @callback patches_to_apply() :: [] | [String.t]
  @callback toolchain() :: atom
end
