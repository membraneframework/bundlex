defmodule Bundlex.IntegrationTest do
  use ExUnit.Case

  @tmp "tmp"

  setup_all do
    File.rm_rf!(@tmp)
    File.cp_r("test_projects", @tmp)
    proj_cmd("mix test")
    :ok
  end

  test "Generated artifacts are present" do
    base_path = "#{@tmp}/example/_build/test/lib/example/priv/bundlex"

    output_files = ["nif/example.so", "cnode/example", "port/example"]

    Enum.each(output_files, fn file -> assert File.exists?("#{base_path}/#{file}") end)
  end

  test "Works after changing project directory" do
    moved_path = move_proj()
    proj_cmd("mix test", project: moved_path, recompile: false)
  end

  test "Works in releases" do
    proj_cmd("mix release", recompile: false)
    File.rename!("#{@tmp}/example/_build/test/rel/example", "#{@tmp}/example_release")
    move_proj()

    proj_cmd("bin/example eval \"{7, _v} = Example.Foo.foo(3, 4)\"",
      project: "#{@tmp}/example_release"
    )
  end

  defp proj_cmd(proj_cmd, opts \\ []) do
    {project, opts} = Keyword.pop(opts, :project, "#{@tmp}/example")
    {env, opts} = Keyword.pop(opts, :env, [])
    {recompile, opts} = Keyword.pop(opts, :recompile, true)

    env =
      [
        {"MIX_ENV", "test"},
        {"BUNDLEX_PATH", File.cwd!()},
        {"BUNDLEX_FORCE_NO_COMPILE", unless(recompile, do: "true")}
        | env
      ]

    assert {_output, 0} =
             System.cmd(
               "sh",
               ["-c", "#{proj_cmd} 1>&2"],
               [cd: project, env: env] ++ opts
             )

    :ok
  end

  # Temporarily moves the project to make sure that
  # nothing depends on it being in original location
  defp move_proj(project \\ "#{@tmp}/example") do
    target_path = "#{project}_moved"
    File.rename!(project, target_path)

    on_exit(fn ->
      File.rename("#{project}_moved", project)
    end)

    target_path
  end
end
