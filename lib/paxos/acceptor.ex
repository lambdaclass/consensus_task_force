defmodule Acceptor do

  ##########################
  ### Public API
  ##########################

  def start(key) do
    spawn(fn -> init(key) end)
  end

  def prepare(pid, from, round) do
    send(pid, {:prepare, {from, self()}, round})
  end

  def accept(pid, from, round, proposal) do
    send(pid, {:accept, {from, self()}, round, proposal})
  end

  def stop(pid) do
    send(pid, :stop)
  end

  def state(pid) do
    send(pid, :state)
  end

  ##########################
  ### Private
  ##########################
  defp init(key) do
    state = %{key: key, promise: Order.null(), voted: Order.null(), accepted: :na}
    acceptor(state)
  end

  ##########################
  ### Main Loop
  ##########################
  def acceptor(state = %{key: key, promise: promise, voted: voted, accepted: accepted}) do
    receive do
      :state ->
        IO.puts("State: #{inspect(state)}")
        acceptor(state)
      {:prepare, {from, proposer}, round} ->
        IO.puts("[Proposer #{from}] --{prepare, #{inspect(round)}}-> [Acceptor #{key}]")
        case round > promise do
          true ->
            send(proposer, {:promise, key, round, voted, accepted})
            acceptor(%{state | promise: round})
          false ->
            send(proposer, {:sorry, key, round})
            acceptor(state)
          end
      {:accept, {from, proposer}, round, proposal} ->
        IO.puts("[Proposer #{from}] --{accept, #{inspect(round)}, #{proposal}}-> [Acceptor #{key}]")
        case round >= promise do
          true ->
            send(proposer, {:vote, key, round})
            case round >= voted do
              true ->
                acceptor(%{state | voted: round, accepted: proposal})
              false ->
                acceptor(state)
            end
          false ->
            send(proposer, {:sorry, key, round})
            acceptor(state)
          end
      :stop ->
        :ok
      msg ->
        IO.puts("Unrecognized message: #{msg}")
        acceptor(state)
    end
  end
end
