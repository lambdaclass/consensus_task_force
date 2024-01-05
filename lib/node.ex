defmodule BasicNode do
  use GenServer

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @impl GenServer
  def init(_init_args) do
    state = %{}
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:ping, from}, state) do
    send(from, :pong)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:pong, state) do
    IO.puts("pong: #{inspect(self())}")
    {:noreply, state}
  end
end
