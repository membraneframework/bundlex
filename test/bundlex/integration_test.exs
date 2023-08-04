defmodule Bundlex.IntegrationTest do
  use ExUnit.Case

  test "Example test project" do
    System.cmd("sh", ["-c", "mix test 1>&2"], cd: "test_projects/example")

    base_path = "test_projects/example/_build/test/lib/example/priv/bundlex/"

    output_files = ["nif/example.so", "cnode/example", "port/example"]

    output_files
    |> Enum.each(fn file ->
      assert File.exists?("#{base_path}#{file}") == true
    end)
  end
end
