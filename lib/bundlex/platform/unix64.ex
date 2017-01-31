defmodule Bundlex.Platform.Unix64 do
  @behaviour Bundlex.Platform

  def extra_otp_configure_options() do
    []
  end


  def required_env_vars() do
    []
  end

  def patches_to_apply() do
    []
  end

  def toolchain() do
    :unix
  end
end
