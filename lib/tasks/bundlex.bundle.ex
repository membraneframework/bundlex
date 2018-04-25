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
  @spec run(OptionParser.argv()) :: :ok
  def run(args) do
    # Parse options
    {opts, _} = OptionParser.parse!(args, aliases: [t: :platform], strict: @switches)

    platform = Bundlex.Platform.get_from_opts!(opts)
    platform_module = Bundlex.Platform.get_module!(platform)
    Mix.shell().info("Building for platform #{platform}")

    # Build
    patches_config = Mix.Config.read!(Path.join(:code.priv_dir(:bundlex), "patches.exs"))

    # Open and validate bundlex config
    config_files =
      Mix.Project.config_files()
      |> Enum.reject(fn file -> Path.basename(file) != "bundlex_project.exs" end)

    case config_files do
      [config_file] ->
        config = Mix.Config.read!(config_file)

        case config do
          [{:bundlex_project, platforms_config}] ->
            case List.keyfind(platforms_config, platform, 0) do
              {_, platform_config} ->
                erlang_version = read_config_key_string!(platform_config, :erlang_version)

                erlang_disabled_apps =
                  read_config_key_list_of_strings!(platform_config, :erlang_disabled_apps)

                elixir_version = read_config_key_string!(platform_config, :elixir_version)

                Mix.shell().info(" * Erlang/OTP version: #{erlang_version}")
                Mix.shell().info(" * Erlang disabled apps: #{inspect(erlang_disabled_apps)}")
                Mix.shell().info(" * Elixir version: #{elixir_version}")

                Mix.shell().info("-- Checking for required env vars")
                verify_env_variables(platform_module)

                Mix.shell().info("-- Cleaning target directory")
                execute_command("rm -rf _target && mkdir -p _target")

                set_up_toolchain(platform_module, platform_config)

                Mix.shell().info("== ERLANG")
                Mix.shell().info("-- Cloning Erlang VM sources")

                execute_command(
                  "cd _target && git clone --depth 1 -b OTP-#{erlang_version} https://github.com/erlang/otp.git"
                )

                Mix.shell().info("-- Building Erlang")
                execute_command("cd _target/otp && ./otp_build autoconf")

                configure_options =
                  Enum.join(
                    platform_module.extra_otp_configure_options ++
                      disabled_apps_configure_options(erlang_disabled_apps),
                    " "
                  )

                execute_command("cd _target/otp && ./otp_build configure #{configure_options}")
                execute_command("cd _target/otp && ./otp_build boot")
                execute_command("cd _target/otp && ./otp_build release")
                apply_patches(platform_module, patches_config, :erlang, :post_compile)

                Mix.Tasks.Escript.run(~w|build|)

              _ ->
                Mix.raise(
                  "Invalid configuration. Unable to find :bundlex, #{inspect(platform)} key in the configuration file."
                )
            end

          _ ->
            Mix.raise(
              "Invalid configuration. Unable to find :bundlex key in the configuration file."
            )
        end

      [] ->
        Mix.raise("Cannot create bundle without configuration. Please create config/bundlex.exs.")
    end
  end

  defp execute_command(cmd) do
    case Mix.shell().cmd(cmd) do
      0 -> 0
      code -> Mix.raise("#{cmd} finished with error #{code}")
    end
  end

  defp set_up_toolchain(platform_module, platform_config) do
    case platform_module.toolchain do
      :android ->
        Mix.shell().info("== ANDROID TOOLCHAIN")
        android_api_version = read_config_key_string!(platform_config, :android_api_version)

        execute_command(
          "$NDK_ROOT/build/tools/make_standalone_toolchain.py --arch arm --api #{
            android_api_version
          } --install-dir _target/android_toolchain"
        )

        new_path = "#{Path.absname("")}/_target/android_toolchain/bin:#{System.get_env("PATH")}"
        System.put_env("PATH", new_path)

      _ ->
        nil
    end
  end

  defp disabled_apps_configure_options(erlang_disabled_apps) do
    erlang_disabled_apps
    |> Enum.map(fn app -> "--without-#{app}" end)
  end

  defp verify_env_variables(platform_module) do
    platform_module.required_env_vars
    |> Enum.each(fn var ->
      value = System.get_env(var)

      case value do
        nil -> Mix.raise("#{var} not defined")
        _ -> Mix.shell().info("#{var}: #{value}")
      end
    end)
  end

  defp apply_patches(platform_module, config, app, stage) do
    case config do
      [{:bundlex_patches, patches_config}] ->
        case List.keyfind(patches_config, app, 0) do
          {_, app_config} ->
            case List.keyfind(app_config, stage, 0) do
              {_, patches} ->
                patches
                |> Enum.filter(fn p ->
                  Enum.member?(platform_module.patches_to_apply, "#{app}/#{p.name}")
                end)
                |> Enum.each(fn p -> apply_patch(app, p) end)
            end
        end
    end
  end

  defp apply_patch(app, %{dir: dir, name: name}) do
    patch_path = Path.join(:code.priv_dir(:bundlex), "patches/#{app}/#{name}.patch")
    Mix.shell().info("-- Applying patch: #{app}/#{name}")
    execute_command("cd _target/#{dir} && patch -p0 < #{patch_path}")
  end

  defp read_config_key_string!(config, key) do
    case List.keyfind(config, key, 0) do
      nil ->
        Mix.raise(
          "Invalid configuration. Unable to find #{inspect(key)} key in the configuration file for selected platform."
        )

      {_, value} ->
        if String.valid?(value) do
          value
        else
          Mix.raise(
            "Invalid configuration. Key #{inspect(key)} in the configuration file for selected platform has value that is not a string."
          )
        end
    end
  end

  defp read_config_key_list_of_strings!(config, key) do
    case List.keyfind(config, key, 0) do
      nil ->
        Mix.raise(
          "Invalid configuration. Unable to find #{inspect(key)} key in the configuration file for selected platform."
        )

      {_, value} ->
        if is_list(value) do
          Enum.each(value, fn item ->
            if not String.valid?(item) do
              Mix.raise(
                "Invalid configuration. Key #{inspect(key)} in the configuration file for selected platform has value that is not a list of strings."
              )
            end
          end)

          value
        else
          Mix.raise(
            "Invalid configuration. Key #{inspect(key)} in the configuration file for selected platform has value that is not a list."
          )
        end
    end
  end
end
