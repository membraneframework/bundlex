defmodule Example.Foo do
  use Bundlex.Loader, nif: :example

  defnif(foo(a, b))
end
