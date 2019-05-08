defmodule Bundlex.Output do
  @moduledoc false

  def info(msg) do
    Mix.shell().info("Bundlex: " <> msg)
  end

  def raise(msg) do
    Mix.raise("Bundlex: " <> msg)
  end
end
