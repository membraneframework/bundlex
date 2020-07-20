defmodule Example.BundlexProject do
  use Bundlex.Project

  def project do
    [
      natives: natives(),
      nifs: nifs(),
      cnodes: cnodes()
    ]
  end

  defp natives do
    [
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["foo_nif.c"],
        interfaces: [:nif]
      ],
      example: [
        deps: [example_lib: :example_lib],
        src_base: "example",
        sources: ["example_cnode.c"],
        interfaces: [:cnode]
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
end
