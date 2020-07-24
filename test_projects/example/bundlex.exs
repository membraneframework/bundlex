defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives(),
      nifs: nifs(),
      cnodes: cnodes(),
      ports: ports()
    ]
  end

  defp natives do
    [
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["foo_nif.c"],
        interface: [:nif]
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

  defp nifs do
    [
      example_nif: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["bar_nif.c"]
      ]
    ]
  end

  defp cnodes do
    [
      example_cnode: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["example_cnode.c"],
      ]
    ]
  end

  defp ports do
    [
      example_port: [
        src_base: "example",
        sources: ["example_port.c"],
      ]
    ]
  end
end
