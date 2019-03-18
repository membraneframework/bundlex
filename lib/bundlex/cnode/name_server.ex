defmodule Bundlex.CNode.NameServer do
  @moduledoc false
  use Agent

  def start_link(opts \\ []) do
    Agent.start_link(
      fn -> %{no: 0, q: Qex.new(), creations: %{}, self_id: SecureRandom.uuid()} end,
      opts ++ [name: __MODULE__]
    )
  end

  def get_self_name() do
    Agent.get(__MODULE__, fn %{self_id: self_id} -> :"bundlex_app_#{self_id}" end)
  end

  def get_name() do
    Agent.get_and_update(__MODULE__, fn state ->
      {name, q, no} =
        case state.q |> Qex.pop() do
          {{:value, v}, q} -> {v, q, state.no}
          {:empty, q} -> {:"bundlex_cnode_#{state.no}_#{state.self_id}", q, state.no + 1}
        end

      {{name, state.creations |> Map.get(name, 0)}, %{state | no: no, q: q}}
    end)
  end

  def return_name(name) do
    Agent.update(__MODULE__, fn state ->
      state
      |> Map.update!(:q, &Qex.push(&1, name))
      |> update_in([:creations, name], &((&1 || 0) + 1))
    end)
  end
end
