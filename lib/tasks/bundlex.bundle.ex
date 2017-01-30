defmodule Mix.Tasks.Bundlex.Bundle do
  use Mix.Task

  @moduledoc """
  Assembles a bundle that is ready to run on given platform platform.

  ## Command line options

    * `--platform` or `-t` - specifies platform platform. It has to be one of
      `windows32`, `windows64`, TODO.
  """

  @shortdoc "Assembles a ready-to-ship bundle of the current applicaton"
  @switches [platform: :string]
  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    {opts, _} = OptionParser.parse!(args, aliases: [t: :platform], strict: @switches)

    # TODO ensure that git and other build tools are in place


    # Determine platform platform
    platform = cond do
      platform = opts[:platform] ->
        platform_module = case platform do
          "windows32" ->
            Bundlex.Platform.Windows32

          "android_armv7" ->
            Bundlex.Platform.AndroidARMv7

          _ ->
            Mix.raise "Cannot create bundle for unknown platform. Given #{platform} which is not known platform."
        end
        platform = String.to_atom(platform)

      true ->
        Mix.raise "Cannot create bundle for unspecified platform. Please pass platform platform as --platform option."
    end

    Mix.shell.info "Building for platform #{platform}"

    # Open and validate bundlex config
    config_files = Mix.Project.config_files()
      |> Enum.reject(fn(file) -> Path.basename(file) != "bundlex_project.exs" end)

    case config_files do
      [config_file] ->
        config = Mix.Config.read!(config_file)

        case config do
          [{:bundlex_project, platforms_config}] ->
            case List.keyfind(platforms_config, platform, 0) do
              {_, platform_config} ->
                erlang_version = read_config_key_string!(platform_config, :erlang_version)
                erlang_disabled_apps = read_config_key_list_of_strings!(platform_config, :erlang_disabled_apps)
                elixir_version = read_config_key_string!(platform_config, :elixir_version)

                Mix.shell.info " * Erlang/OTP version: #{erlang_version}"
                Mix.shell.info " * Erlang disabled apps: #{inspect(erlang_disabled_apps)}"
                Mix.shell.info " * Elixir version: #{elixir_version}"

                # TODO
                # configure = ["./configure"] ++ platform_module.extra_configure_options()

              _ ->
                Mix.raise "Invalid configuration. Unable to find :bundlex, #{inspect(platform)} key in the configuration file."
            end

          _ ->
            Mix.raise "Invalid configuration. Unable to find :bundlex key in the configuration file."
        end

      [] ->
        Mix.raise "Cannot create bundle without configuration. Please create config/bundlex.exs."
    end
  end


  defp read_config_key_string!(config, key) do
    case List.keyfind(config, key, 0) do
      nil ->
        Mix.raise "Invalid configuration. Unable to find #{inspect(key)} key in the configuration file for selected platform."

      {_, value} ->
        if String.valid?(value) do
          value
        else
          Mix.raise "Invalid configuration. Key #{inspect(key)} in the configuration file for selected platform has value that is not a string."
        end
    end
  end


  defp read_config_key_list_of_strings!(config, key) do
    case List.keyfind(config, key, 0) do
      nil ->
        Mix.raise "Invalid configuration. Unable to find #{inspect(key)} key in the configuration file for selected platform."

      {_, value} ->
        if is_list(value) do
          Enum.each(value, fn(item) ->
            if not String.valid?(item) do
              Mix.raise "Invalid configuration. Key #{inspect(key)} in the configuration file for selected platform has value that is not a list of strings."
            end
          end)
          value

        else
          Mix.raise "Invalid configuration. Key #{inspect(key)} in the configuration file for selected platform has value that is not a list."
        end
    end
  end
end
