defmodule Bundlex.Helper.GitHelper do
  def lfs_present? do
    Mix.shell().cmd("git config --get-regexp ^filter\.lfs\.", quiet: true) == 0
  end
end
