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

  test "native with interface port" do
    test_port(:example)
  end

  test "port without interface" do
    test_port(:example_port)
  end

  defp test_cnode(name) do
    require Bundlex.CNode
    assert {:ok, cnode} = Bundlex.CNode.start_link(name)
    assert 10.0 = Bundlex.CNode.call(cnode, {:foo, 5.0, 5.0})
  end

  defp test_port(name) do
    require Bundlex.Port
    _port = Bundlex.Port.open(name)

    receive do
      {_port, {:data, msg}} -> assert msg == 'bundlex_port_test'
    after
      2_000 -> raise "timeout"
    end
  end
end
