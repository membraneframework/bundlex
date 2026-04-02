defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives()
    ]
  end

  defp get_ffmpeg() do
    [
      {:precompiled,
       Membrane.PrecompiledDependencyProvider.get_dependency_url(:ffmpeg, version: "6.0.1"),
       ["libswscale", "libavcodec"]},
      {:pkg_config, ["libswscale", "libavcodec"]}
    ]
  end

  defp natives do
    [
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["foo_nif.c"],
        interface: [:nif],
        os_deps: [
          {:pkg_config, "libpng"}, # deprecated syntax, testing for regression
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
