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

  def get_mixfile_env(application) do
    case Application.get_env(:bundlex, application) do
      %Macro.Env{} = env -> {:ok, env}
      nil -> {:error, {:mixfile_env_undefined, application}}
      invalid_env -> {:error, {:mixfile_env_invalid, application, invalid_env}}
    end
  end

end
