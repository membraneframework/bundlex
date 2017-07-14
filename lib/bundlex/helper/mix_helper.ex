defmodule Bundlex.Helper.MixHelper do
  @moduledoc """
  Module containing helper functions that ease retreiving certain values from
  Mix configuration files.
  """


  @doc """
  Helper function for retreiving app name from mix.exs and failing if it was
  not found.
  """
  @spec get_app! :: atom
  def get_app! do
    case Mix.Project.config() |> List.keyfind(:app, 0) do
      {:app, app} ->
        app

      _ ->
        Mix.raise "Unable to determine app name, check if :app key is present in return value of project/0 in mix.exs"
    end
  end


  @doc """
  Helper function for retreiving configuration for bundlex for given build type
  (library or project) and platform.
  """
  @spec get_config!(atom, :bundlex_lib | :bundlex_project, Bundlex.Platform.platform_name_t) :: any
  def get_config!(app, build_type, platform_name) do
    case Mix.Project.config() |> List.keyfind(:config_path, 0) do
      {:config_path, config_path} ->
        config = Mix.Config.read!(config_path)
        case config |> List.keyfind(app, 0) do
          {app, app_config} ->
            case app_config |> List.keyfind(build_type, 0) do
              {build_type, build_type_config} ->
                case build_type_config |> List.keyfind(platform_name, 0) do
                  {platform_name, platform_config} ->
                    platform_config

                  _ ->
                    Mix.raise "Unable to read config for app #{inspect(app)} with keys #{inspect(build_type)}, #{inspect(platform_name)}, check your #{config_path}"
                end

              _ ->
                Mix.raise "Unable to read config for app #{inspect(app)} with key #{inspect(build_type)}, check your #{config_path}"
            end

          _ ->
            Mix.raise "Unable to read config for app #{inspect(app)}, check your #{config_path}"
        end

      _ ->
        Mix.raise "Unable to determine config path"
    end
  end
end
