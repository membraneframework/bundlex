defmodule Bundlex.Output do
  def info1(msg) do
    Mix.shell.info("!!! " <> String.upcase(msg))
  end


  def info2(msg) do
    Mix.shell.info("### " <> String.upcase(msg))
  end


  def info3(msg) do
    Mix.shell.info("  - " <> msg)
  end
end
