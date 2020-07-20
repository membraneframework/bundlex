defmodule ExampleTest do
  use ExUnit.Case

  test "native with interface NIF" do
    defmodule Foo do
      use Bundlex.Loader, nif: :example

      defnif(foo(a, b))
    end
    assert 10 = Foo.foo(5, 5)
  end

  test "nif without interface" do
    defmodule Bar do
      use Bundlex.Loader, nif: :example_nif

      defnif(bar(a, b))
    end
    assert 0 = Bar.bar(5, 5)
  end

  test "native with interface CNode" do
    test_cnode(:example)
  end


  test "cnode without interface" do
    test_cnode(:example_cnode)
  end

  defp test_cnode(name) do
    require Bundlex.CNode
    assert {:ok, cnode} = Bundlex.CNode.start_link(name)
    assert 10.0 = Bundlex.CNode.call(cnode, {:foo, 5.0, 5.0})
  end
end
