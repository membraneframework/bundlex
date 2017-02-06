defmodule Bundlex.MixHelper do
  @doc """
  Helper function for retreiving app name from mix.exs and failing if it was
  not found.
  """
  @spec get_app! :: atom
  def get_app! do
    app = case Mix.Project.config() |> List.keyfind(:app, 0) do
      {:app, app} ->
        app

      _ ->
        Mix.raise "Unable to determine app name, check if :app key is present in return value of project/0 in mix.exs"
    end
  end
end
