defmodule Paxos.Acceptor do
  @moduledoc """
  State machine that implements the Paxos protocol from the acceptor side.
  Each function returns the updated state and a message to be sent to the proposer (or nil).
  """

  # NOTE: {0, 0} < {0, #Reference<_>}
  defstruct committed: nil, last_b: {0, 0}, last_vote: nil

  # Protocol primitives

  # PREPARE

  # If the number is not greater than the last one, we ignore the message.
  def prepare(%{last_b: last_b} = state, b) when b <= last_b, do: {state, nil}

  # Else, we store the new ballot number, and send back our last vote.
  def prepare(%{last_vote: last_vote} = state, b) do
    new_state = %{state | last_b: b}
    {new_state, {:last_vote, last_vote}}
  end

  # ACCEPT

  # If the ballot number is not the last one, we ignore the message.
  def accept(%{last_b: last_b} = state, b, _) when b != last_b, do: {state, nil}

  # Else, we update our last vote, and send it back to the proposer.
  def accept(state, b, v) do
    new_state = %{state | last_vote: {b, v}}
    {new_state, :vote}
  end

  # COMMIT

  # No need to check anything as we are non-BFT, so everybody's honest.
  def commit(state, v) do
    new_state = %{state | committed: v}
    {new_state, nil}
  end

  # Utilities
  def new, do: %__MODULE__{}
  def committed_value(%{committed: v}), do: v
end
