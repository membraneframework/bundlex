defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end


  defp get_ffmpeg_url() do
    case Bundlex.get_target() do
      %{os: "linux"} -> {:precompiled, "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n4.4-latest-linux64-gpl-shared-4.4.tar.xz/"}
      %{architecture: "x86_64", os: "darwin"<>_rest_of_os_name} -> {:precompiled, "https://github.com/membraneframework-labs/precompiled_ffmpeg/releases/download/version1/ffmpeg_macos_intel.tar.gz"}
      _other -> nil
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
          {[get_ffmpeg_url(), :pkg_config], ["libswscale", "libavcodec"]},
          {:pkg_config, "libpng"}
        ],
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
