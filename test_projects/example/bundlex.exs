defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end


  defp get_ffmpeg_url() do
    case Bundlex.get_target() do
      {_architecture, _vendor, "linux"} -> "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n4.4-latest-linux64-gpl-shared-4.4.tar.xz/"
      {"x86_64", _vendor, "darwin"<>_rest_of_os_name} -> "https://github.com/membraneframework-labs/precompiled_ffmpeg/releases/download/version1/ffmpeg_macos_intel.tar.gz"
      _other -> :unavailable
    end
  end

  defp natives do
    [
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["foo_nif.c"],
        interface: [:nif],
        os_deps: [
          {get_ffmpeg_url(), ["libswscale", "libavcodec"]},
          "libpng"
        ],
        pkg_configs: ["libswresample"]
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
