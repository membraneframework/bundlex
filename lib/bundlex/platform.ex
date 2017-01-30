defmodule Bundlex.Platform do
  @callback extra_otp_build_arguments() :: [] | [String.t]
  @callback extra_configure_options() :: [] | [String.t]
end
