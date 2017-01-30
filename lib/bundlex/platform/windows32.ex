defmodule Bundlex.Platform.Windows32 do
  @behaviour Bundlex.Platform


  def extra_otp_build_arguments() do
    []
  end


  def extra_configure_options() do
    []
  end
end
