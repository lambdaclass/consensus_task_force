# To run the example:
#  mix run examples/paxos_example.exs 2> /dev/null

alias Paxos.Acceptor
alias Paxos.Proposer

acceptor_1 = Acceptor.new()
acceptor_2 = Acceptor.new()
acceptor_3 = Acceptor.new()

proposer = Proposer.new("Paxos is a consensus algorithm", 3)

IO.puts("Paxos example with 3 acceptors and 1 proposer")
IO.puts("")

# ROUND 1

IO.puts("Round 1")
IO.puts("")

## PREPARE

{proposer, {:prepare, b}} = Proposer.prepare(proposer)
IO.puts("Proposer wants to start a new ballot numbered #{elem(b, 0)}")
IO.puts("")
{acceptor_1, {:last_vote, a_answer}} = Acceptor.prepare(acceptor_1, b)
IO.puts("A answers with their last vote: #{inspect(a_answer)}")

{acceptor_2, {:last_vote, b_answer}} = Acceptor.prepare(acceptor_2, b)
IO.puts("B answers with their last vote: #{inspect(b_answer)}")

# {acceptor_3, {:last_vote, c_answer}} = Acceptor.prepare(acceptor_3, b)
IO.puts("C doesn't receive the message")
IO.puts("")

## ACCEPT

IO.puts("Only the message from A arrives...")
{proposer, nil} = Proposer.accept(proposer, [a_answer])
IO.puts("And the proposer ends the ballot")
IO.puts("")

# ROUND 2

IO.puts("Round 2")
IO.puts("")

## PREPARE

{proposer, {:prepare, b}} = Proposer.prepare(proposer)
IO.puts("Proposer wants to start a new ballot numbered #{elem(b, 0)}")
IO.puts("")
{acceptor_1, {:last_vote, a_answer}} = Acceptor.prepare(acceptor_1, b)
IO.puts("A answers with their last vote: #{inspect(a_answer)}")

{acceptor_2, {:last_vote, b_answer}} = Acceptor.prepare(acceptor_2, b)
IO.puts("B answers with their last vote: #{inspect(b_answer)}")

{acceptor_3, {:last_vote, c_answer}} = Acceptor.prepare(acceptor_3, b)
IO.puts("C answers with their last vote: #{inspect(c_answer)}")
IO.puts("")
IO.puts("All answers arrive...")

## ACCEPT

{proposer, {:accept, b, v}} = Proposer.accept(proposer, [a_answer, b_answer, c_answer])
IO.puts("Proposer starts a ballot numbered #{elem(b, 0)} with value #{inspect(v)}")

IO.puts("")
{acceptor_1, :vote} = Acceptor.accept(acceptor_1, b, v)
IO.puts("A votes for")

{acceptor_2, :vote} = Acceptor.accept(acceptor_2, b, v)
IO.puts("B votes for")

# {acceptor_3, :vote} = Acceptor.accept(acceptor_3, b, v)
IO.puts("C didn't receive the message")

IO.puts("")
IO.puts("All answers arrive...")

## COMMIT

{proposer, {:commit, v}} = Proposer.commit(proposer, [:vote, :vote])
IO.puts("Proposer commits the value #{inspect(v)}, and broadcasts it")

{acceptor_1, nil} = Acceptor.commit(acceptor_1, v)
IO.puts("A commits the value")

{acceptor_2, nil} = Acceptor.commit(acceptor_2, v)
IO.puts("B commits the value")

{acceptor_3, nil} = Acceptor.commit(acceptor_3, v)
IO.puts("C commits the value")

IO.puts("")
committed_value = Acceptor.committed_value(acceptor_2)
IO.puts("The network has reached consensus: #{inspect(committed_value)}")
