defmodule Bundlex.Config do

  @type t :: Keyword.t

  def parse(config) do
    {:ok, config}
  end

  def get_platform(config, platform_name) do
    platforms = config |> Keyword.get(:platforms, [])
    with :error <- platforms |> Keyword.fetch(platform_name),
         :error <- platforms |> Keyword.fetch(:default) do
      {:error, {:no_config_for_platform, platform_name}}
    end
  end

end
