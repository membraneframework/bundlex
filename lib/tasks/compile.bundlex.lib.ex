defmodule Mix.Tasks.Compile.Bundlex.Lib do
  use Mix.Task
  alias Bundlex.Makefile
  alias Bundlex.Helper.MixHelper
  alias Bundlex.Helper.ErlangHelper


  @moduledoc """
  Builds a library for the given platform.
  """

  @shortdoc "Builds a library for the given platform"

  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    :ok = Application.ensure_started(:porcelain)

    # Get app
    app = MixHelper.get_app!()
    Bundlex.Output.info1 "Bulding Bundlex Library \"#{app}\""

    # Parse options
    Bundlex.Output.info2 "Target platform"
    {platform_name, platform_module} = Bundlex.Platform.get_current_platform!()
    Bundlex.Output.info3 "Building for platform #{platform_name}"

    # Configuration
    build_config = MixHelper.get_config!(app, :bundlex_lib, platform_name)

    # Toolchain
    Bundlex.Output.info2 "Toolchain"
    before_all = platform_module.toolchain_module.before_all!(platform_name)

    # NIFs
    nif_compiler_commands = case build_config |> List.keyfind(:nif, 0) do
      {:nif, nifs_config} ->
        Bundlex.Output.info2 "NIFs"

        erlang_includes = ErlangHelper.get_includes!(platform_name)

        Bundlex.Output.info3 "Found Erlang include dir in #{erlang_includes}"

        compiler_commands =
          nifs_config
          |> Enum.reduce([], fn({nif_name, nif_config}, acc) ->
            Bundlex.Output.info3 to_string(nif_name)

            # If no erlang include found do not add it to all includes
            includes = case nif_config |> List.keyfind(:includes, 0) do
              {:includes, includes} ->
                case erlang_includes do
                  nil -> includes
                  _ -> [erlang_includes|includes]
                end
              _ ->
                case erlang_includes do
                  nil -> []
                  _ -> erlang_includes
                end
            end

            libs = case nif_config |> List.keyfind(:libs, 0) do
              {:libs, libs} -> libs
              _ -> []
            end

            pkg_configs = case nif_config |> List.keyfind(:pkg_configs, 0) do
              {:pkg_configs, pkg_configs} -> pkg_configs
              _ -> []
            end

            sources = case nif_config |> List.keyfind(:sources, 0) do
              {:sources, sources} -> sources
              _ -> Mix.raise "NIF #{nif_name} does not define any sources"
            end

            acc ++ platform_module.toolchain_module.compiler_commands(includes, libs, sources, pkg_configs, nif_name)
          end)

        compiler_commands

      _ ->
        []
    end

    # Build & run makefile
    Bundlex.Output.info2 "Building"
    Makefile.new
    |> Makefile.append_commands!(before_all)
    |> Makefile.append_commands!(nif_compiler_commands)
    |> Makefile.run!(platform_name)

    Bundlex.Output.info2 "Done"
  end
end
