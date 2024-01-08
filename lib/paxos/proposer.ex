defmodule Proposer do

  @timeout 200
  @backoff 10
  @delay 20

  ##########################
  ### Public API
  ##########################

  def start(key, proposal, acceptors) do
    spawn(fn -> init(key, proposal, acceptors) end)
  end

  ##########################
  ### Private
  ##########################
  defp init(key, proposal, acceptors) do
    round = Order.one(key)
    state = %{key: key, backoff: @backoff, round: round, proposal: proposal, acceptors: acceptors}
    run_round(state)
  end

  def run_round(state = %{key: key, backoff: backoff, round: round, proposal: proposal, acceptors: acceptors}) do
    case ballot(key, round, proposal, acceptors) do
      {:ok, decision} ->
        IO.puts("#{key} decided #{decision} in round #{inspect(round)}")
        {:ok, decision}
      :abort ->
        :timer.sleep(:rand.uniform(backoff))
        round = Order.inc(round)
        run_round(%{state | backoff: 2*backoff, round: round})
    end
  end

  def ballot(key, round, proposal, acceptors) do
    IO.puts("[Proposer #{key}] -> preparing proposal #{proposal} at round #{inspect(round)}")
    prepare(key, round, acceptors)
    quorum = div(length(acceptors), 2) + 1
    max = Order.null()
    case collect(key, quorum, round, max, proposal) do
      {:accepted, value} ->
        accept(key, round, value, acceptors)
        case vote(quorum, key, round) do
          :ok ->
            {:ok, value}
          :abort ->
            :abort
        end
      :abort ->
        :abort
    end
  end

  def collect(key, 0, _round, _max, proposal) do
    IO.puts("[Proposer #{key}] -> has quorum for #{inspect(proposal)}")
    {:accepted, proposal}
  end

  def collect(key, n, round, max, proposal) do
    receive do
      {:promise, from, ^round, voted, :na} ->
        IO.puts("[Acceptor #{from}] --{promise, #{inspect(round)}, #{inspect(voted)}, na}}-> [Proposer #{key}]")
        collect(key, n - 1, round, max, proposal)
      {:promise, from, ^round, voted, value} ->
        IO.puts("[Acceptor #{from}] --{promise, #{inspect(round)}, #{inspect(voted)}, #{value}}}-> [Proposer #{key}]")
        case round > voted do
          true ->
            collect(key, n - 1, round, round, value)
          false ->
            collect(key, n - 1, round, voted, value)
        end
      {:promise, from, round, voted, value} ->
        IO.puts("[Acceptor #{from}] --{promise, #{inspect(round)}, #{inspect(voted)}, #{value}}}-> [Proposer #{key}]")
        collect(key, n, round, max, proposal)
      {:sorry, from, ^round} ->
        IO.puts("[Acceptor #{from}] --{sorry, #{inspect(round)}}-> [Proposer #{key}]")
        collect(key, n, round, max, proposal)
      {:sorry, from, round} ->
        IO.puts("[Acceptor #{from}] --{sorry, #{inspect(round)}}-> [Proposer #{key}]")
        collect(key, n, round, max, proposal)
      after
        @timeout ->
          :abort
    end
  end

  def vote(0, key, _round) do
    IO.puts("[Proposer #{key}] reached 0")
    :ok
  end

  def vote(n, key, round) do
    receive do
      {:vote, from, ^round} ->
        IO.puts("[Acceptor #{from}] --{vote, #{inspect(round)}}-> [Proposer #{key}]")
        vote(n - 1, key, round)
      {:vote, from, round} ->
        IO.puts("[Acceptor #{from}] --{vote, #{inspect(round)}}-> [Proposer #{key}]")
        vote(n, key, round)
      {:sorry, from, ^round} ->
        IO.puts("[Acceptor #{from}] --{sorry, #{inspect(round)}}-> [Proposer #{key}]")
        vote(n, key, round)
      {:sorry, from, round} ->
        IO.puts("[Acceptor #{from}] --{sorry, #{inspect(round)}}-> [Proposer #{key}]")
        vote(n, key, round)
      after
        @timeout ->
          :abort
    end
  end

  def prepare(key, round, acceptors) do
    Enum.each(acceptors, fn acceptor -> Acceptor.prepare(acceptor, key, round) end)
  end

  def accept(key, round, proposal, acceptors) do
    Enum.each(acceptors, fn acceptor -> Acceptor.accept(acceptor, key, round, proposal) end)
  end

end
