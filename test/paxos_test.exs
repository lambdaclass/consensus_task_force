defmodule PaxosTest do
  use ExUnit.Case
  doctest Paxos.Node

  alias Paxos.Node

  test "simple network reaches consensus" do
    [n1 | _] = nodes = Node.setup_network(3)
    assert Node.propose(n1, :something) == :ok
    assert nodes |> Enum.map(&Node.get_log(&1)) |> Enum.all?(&match?([{_, :something}], &1))
  end
end
