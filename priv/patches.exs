use Mix.Config

config :bundlex_patches, :erlang,
  post_compile: [
    %{
      name: 'android_shell',
      dir: 'otp'
    }
  ]