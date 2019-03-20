defmodule Bundlex.Output do
  @moduledoc false

  def info(msg) do
    Mix.shell().info("Bundlex: " <> msg)
  end

  def info_main(msg) do
    info("!!! " <> msg)
  end

  def info_stage(msg) do
    info("### " <> msg)
  end

  def info_substage(msg) do
    info("  - " <> msg)
  end

  def raise(msg) do
    Mix.raise("Bundlex: " <> msg)
  end
end
