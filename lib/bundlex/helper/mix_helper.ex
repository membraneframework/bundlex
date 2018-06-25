defmodule Bundlex.Helper.MixHelper do
  @moduledoc """
  Module containing helper functions that ease retreiving certain values from
  Mix configuration files.
  """

  alias Bundlex.Output
  use Bundlex.Helper

  @path_store_name :bundlex_path_store

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
        Output.raise(
          "Unable to determine app name, check if :app key is present in return value of project/0 in mix.exs"
        )
    end
  end

  @doc """
  Stores current project directory in an agent.
  This is necessary because `Mix.Project.deps_paths/0` sometimes return invalid
  paths when dependencies are given by path
  (see https://github.com/elixir-lang/elixir/issues/7561). Such dependencies are always
  recompiled, thus proper path is always stored and can be retrieved by dependent
  projects.
  """
  def store_project_dir() do
    Agent.start(fn -> %{} end, name: @path_store_name)

    with {:ok, dir} <- get_project_dir() do
      Agent.update(@path_store_name, &Map.put(&1, get_app!(), dir))
    end
  end

  @doc """
  Returns root directory of the currently compiled project.
  """
  def get_project_dir() do
    {:ok, Mix.ProjectStack.peek().file |> Path.dirname()}
  end

  @doc """
  Returns root directory of the project of given application.
  """
  def get_project_dir(application) do
    if application == get_app!() do
      get_project_dir()
    else
      Agent.start(fn -> %{} end, name: @path_store_name)

      case Agent.get(@path_store_name, & &1[application]) || Mix.Project.deps_paths()[application] do
        nil -> {:error, {:unknown_application, application}}
        path -> {:ok, path}
      end
    end
  end
end
