defmodule Bundlex.Platform.AndroidARMv7 do
  @behaviour Bundlex.Platform

  def extra_otp_configure_options() do
    ["--xcomp-conf=xcomp/erl-xcomp-arm-android.conf"]
  end


  def required_env_vars() do
    ["NDK_ROOT", "NDK_PLAT"]
  end

  def patches_to_apply() do
    ["erlang/android_shell"]
  end

  def toolchain() do
    :android
  end
end
