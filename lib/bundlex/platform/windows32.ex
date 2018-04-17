defmodule Bundlex.Platform.Windows32 do
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

  def toolchain_module() do
    Bundlex.Toolchain.VisualStudio
  end
end
