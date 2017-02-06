defmodule Mix.Tasks.Compile.Bundlex.Lib do
  use Mix.Task
  alias Bundlex.Makefile
  alias Bundlex.MixHelper


  @moduledoc """
  Builds a library for the given platform.
  """

  @shortdoc "Builds a library for the given platform"
  @switches [
    platform: :string,
    "no-deps": :string,
    "no-archives-check": :string,
    "no-elixir-version-check": :string,
    "no-warnings-as-errors": :string,
  ]

  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    # Get app
    app = MixHelper.get_app!()
    Bundlex.Output.info1 "Bulding Bundlex Library for app #{app}"


    # Get config


    # Parse options
    Bundlex.Output.info2 "Target platform"
    {opts, _} = OptionParser.parse!(args, aliases: [t: :platform], switches: @switches)

    {platform, platform_module} = Bundlex.Platform.get_platform_from_opts!(opts)
    Bundlex.Output.info3 "Building for platform #{platform}"


    # Toolchain
    Bundlex.Output.info2 "Toolchain"
    before_all = platform_module.toolchain_module.before_all!(platform)


    # Build makefile
    Makefile.new
    |> Makefile.append_commands!(before_all)
    |> Makefile.save!(platform)
  end
end
