defmodule Bundlex.Helper.MixHelper do
  @moduledoc """
  Module containing helper functions that ease retreiving certain values from
  Mix configuration files.
  """

  alias Bundlex.Config

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

  @spec get_config :: {:ok, Config.t}
  def get_config() do
    Mix.Project.config()
    |> Keyword.get(:bundlex_project)
    |> get_module_config()
  end

  def get_module_config(module) do
    with true <- function_exported?(module, :project, 0) do
      {:ok, module.project()}
    else
      _ -> {:error, :no_config}
    end
  end


end
