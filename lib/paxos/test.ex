defmodule Test do

  def start() do
    a = Acceptor.start(1)
    b = Acceptor.start(2)
    c = Acceptor.start(3)
    d = Acceptor.start(4)
    e = Acceptor.start(5)
    acceptors = [a, b, c, d, e]
    Proposer.start(6, "green", acceptors)
    Proposer.start(7, "red", acceptors)
    Proposer.start(8, "blue", acceptors)
    acceptors
  end

  def stop(acceptors) do
    acceptors |> Enum.each(fn acceptor -> Acceptor.stop(acceptor) end)
  end
end
