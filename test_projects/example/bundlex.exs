defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end

  defmodule PrecompiledFFmpeg do
    use Bundlex.PrecompiledDependency

    @impl true
    def get_build_url({_architecture, _vendor, "linux"}) do
      "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n4.4-latest-linux64-gpl-shared-4.4.tar.xz/"
    end

    @impl true
    def get_build_url(_other_target) do
      :unavailable
    end

    @impl true
    def get_headers_path(path, _target) do
      "#{path}/include"
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
          {PrecompiledFFmpeg, [:libswscale, :libavcodec]},
          :libpng
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
