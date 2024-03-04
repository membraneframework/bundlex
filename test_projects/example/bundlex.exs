defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end

  defp get_ffmpeg() do
    url =
      case Bundlex.get_target() do
        %{abi: "musl"} ->
          nil

        %{architecture: "aarch64", os: "linux"} ->
          "https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2023-11-30-12-55/ffmpeg-n6.0.1-linuxarm64-gpl-shared-6.0.tar.xz"

        %{architecture: "x86_64", os: "linux"} ->
          "https://github.com/BtbN/FFmpeg-Builds/releases/download/autobuild-2023-11-30-12-55/ffmpeg-n6.0.1-linux64-gpl-shared-6.0.tar.xz"

        %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
          "https://github.com/membraneframework-precompiled/precompiled_ffmpeg/releases/latest/download/ffmpeg_macos_intel.tar.gz"

        %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
          "https://github.com/membraneframework-precompiled/precompiled_ffmpeg/releases/latest/download/ffmpeg_macos_arm.tar.gz"

        _other ->
          nil
      end


    [{:precompiled, url, ["libswscale", "libavcodec"]}]
  end

  defp natives do
    [
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["foo_nif.c"],
        interface: [:nif],
        os_deps: [
          {:pkg_config, "libcrypt"}, # deprecated syntax, testing for regression
          ffmpeg: get_ffmpeg(),
        ]
      ],
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["example_cnode.c"],
        interface: [:cnode]
      ],
      example: [
        src_base: "example",
        sources: ["example_port.c"],
        interface: :port
      ]
    ]
  end
end
