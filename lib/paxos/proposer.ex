defmodule Paxos.Proposer do
  @moduledoc """
  State machine that implements the Paxos protocol from the proposer side.
  Each function returns the updated state and a message to be broadcast to the acceptors (or nil).

  ## Assumptions
  - The acceptors are honest.
  - Messages won't be duplicated.
  - Messages from older ballots won't arrive in the current ballot.
  """

  # NOTE: {0, 0} < {0, #Reference<_>}
  defstruct [:id, :value, :n_majority, committed: nil, last_b: {0, 0}, last_value: nil]

  # Protocol primitives

  # PREPARE

  # We increment the ballot number, and send it to the acceptors.
  def prepare(%{last_b: {bn, _}, id: id} = state) do
    b = {bn + 1, id}
    new_state = %{state | last_b: b}
    {new_state, {:prepare, b}}
  end

  # ACCEPT

  # If we haven't reached a majority, we can't proceed.
  def accept(%{n_majority: n_majority} = state, responses) when length(responses) < n_majority,
    do: {state, nil}

  # Else, we choose the value of the highest-numbered vote, and send it to the acceptors.
  def accept(%{last_b: last_b, value: value} = state, responses) do
    v = responses |> Enum.reject(&is_nil/1) |> choose_highest_vote(value)
    new_state = %{state | last_value: v}

    {new_state, {:accept, last_b, v}}
  end

  defp choose_highest_vote([], value), do: value
  defp choose_highest_vote(last_votes, _), do: last_votes |> Enum.max_by(&elem(&1, 0)) |> elem(1)

  # COMMIT

  # If we don't receive votes from a majority, we can't commit the value.
  def commit(%{n_majority: n_majority} = state, responses) when length(responses) < n_majority,
    do: {state, nil}

  # Else, we commit the value and broadcast it.
  def commit(%{last_value: v} = state, _responses) do
    new_state = %{state | committed: v}
    {new_state, {:commit, v}}
  end

  # Utilities
  def new(value, total_nodes) do
    id = make_ref()
    n_majority = div(total_nodes, 2) + 1
    %__MODULE__{id: id, value: value, n_majority: n_majority}
  end

  def committed_value(%{committed: v}), do: v
end
