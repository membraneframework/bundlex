defmodule Example.Lib.BundlexProject do
  use Bundlex.Project

  def project do
    [
      libs: libs(),
    ]
  end

  defp libs do
    [
      example_lib: [
        src_base: "example_lib",
        sources: ["example_lib_nif.c"],
        interface: [:nif]
      ],
      example_lib: [
        src_base: "example_lib",
        sources: ["example_lib_cnode.c"],
        interface: :cnode
      ],
    ]
  end
end
