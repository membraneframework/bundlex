defmodule Bundlex.IntegrationTest do
  use ExUnit.Case

  test "Example test project" do
    assert {_output, 0} = System.cmd("bash", ["-c", "mix test 1>&2"], cd: "test_projects/example")

    base_path = "test_projects/example/_build/test/lib/example/priv/bundlex/"

    output_files = [
      "cnode/example",
      "cnode/example_cnode",
      "nif/example.so",
      "nif/example_nif.so"
    ]

    output_files
    |> Enum.each(fn file ->
      assert File.exists?("#{base_path}#{file}") == true
    end)
  end
end
