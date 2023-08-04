defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives(),
    ]
  end

  defp natives do
    [
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["foo_nif.c"],
        interface: [:nif],
        os_deps: [precompiled: {"https://github.com/BtbN/FFmpeg-Builds/releases/download/latest", [:avcodec, :libswscale]}, pkgconfig: :libpcre]
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
