defmodule Mix.Tasks.Bundlex.Build.Lib do
  use Mix.Task
  alias Bundlex.Makefile


  @moduledoc """
  Builds a library for the given platform.
  """

  @shortdoc "Builds a library for the given platform"
  @switches [platform: :string]
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    # Parse options
    {opts, _} = OptionParser.parse!(args, aliases: [t: :platform], strict: @switches)

    {platform, platform_module} = Bundlex.Platform.get_platform_from_opts!(opts)
    Mix.shell.info "Building for platform #{platform}"

    # Build makefile
    makefile =
      Makefile.new()
      |> Makefile.append_commands!(platform_module.toolchain_module.before_all!(platform))

    # FIXME
    IO.puts inspect(makefile)
  end
end
