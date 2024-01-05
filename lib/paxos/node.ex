defmodule Paxos.Node do
  use GenServer

  @type entry :: any()
  @type log :: [{integer(), entry()}]
  @type seq_number :: {integer(), pid()}

  ##########################
  ### Public API
  ##########################

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @spec get_log(pid()) :: {:ok, log()}
  def get_log(pid), do: GenServer.call(pid, :get_log)

  @spec prepare(pid(), seq_number()) :: :prepared | {:not_prepared, seq_number()}
  def prepare(pid, n), do: GenServer.call(pid, {:prepare, n})

  @spec accept(pid(), seq_number(), entry()) :: :accepted | {:not_accepted, seq_number()}
  def accept(pid, n, entry), do: GenServer.call(pid, {:accept, n, entry})

  @spec propose(pid(), entry()) :: :ok | {:error, :not_prepared | :not_accepted}
  def propose(pid, entry), do: GenServer.call(pid, {:propose, entry})

  # TODO: move?
  @spec setup_network(non_neg_integer()) :: [pid()]
  def setup_network(node_count) do
    Enum.reduce(1..node_count, [], fn _, acc ->
      {:ok, pid} = start_link(acc)
      [pid | acc]
    end)
  end

  ##########################
  ### GenServer Callbacks
  ##########################

  @impl GenServer
  def init(peers) do
    add_peers(peers)
    state = %{peers: peers, log: [], last_seq_n: {0, self()}}
    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_log, _, %{log: log} = state), do: {:reply, log, state}

  @impl GenServer
  def handle_call({:prepare, n}, _, %{last_seq_n: last_seq_n} = state) when n <= last_seq_n do
    {:reply, {:not_prepared, last_seq_n}, state}
  end

  @impl GenServer
  def handle_call({:prepare, seq_n}, _, state) do
    {:reply, :prepared, %{state | last_seq_n: seq_n}}
  end

  @impl GenServer
  def handle_call({:accept, seq_n, _}, _, %{last_seq_n: last_seq_n} = state)
      when seq_n < last_seq_n do
    {:reply, {:not_accepted, last_seq_n}, state}
  end

  @impl GenServer
  def handle_call({:accept, seq_n, entry}, _, %{log: log} = state) do
    {:reply, :accepted, %{state | last_seq_n: seq_n, log: [{seq_n, entry} | log]}}
  end

  @impl GenServer
  def handle_call({:propose, entry}, _, %{last_seq_n: {n, _}, peers: peers} = state) do
    count = length(peers) + 1
    seq_n = {n + 1, self()}
    # NOTE: there's no +1 because we subtract our own vote
    needed_votes = div(count, 2)

    with :ok <- try_prepare(peers, seq_n, needed_votes),
         :ok <- try_accept(peers, seq_n, entry, needed_votes) do
      {:reply, :ok, %{state | last_seq_n: seq_n, log: [{seq_n, entry} | state.log]}}
    else
      err -> {:reply, err, state}
    end
  end

  @impl GenServer
  def handle_info({:new_peer, pid}, %{peers: peers} = state) do
    {:noreply, %{state | peers: [pid | peers]}}
  end

  ##########################
  ### Private functions
  ##########################
  defp add_peers(peers) do
    pid = self()
    peers |> Enum.each(&send(&1, {:new_peer, pid}))
  end

  defp try_prepare(peers, seq_n, needed) do
    peers
    |> Stream.map(&prepare(&1, seq_n))
    |> Stream.filter(&(&1 == :prepared))
    |> Stream.take(needed)
    |> Enum.count()
    |> then(&if &1 >= needed, do: :ok, else: {:error, :not_prepared})
  end

  defp try_accept(peers, seq_n, entry, needed) do
    peers
    |> Stream.map(&accept(&1, seq_n, entry))
    |> Stream.filter(&(&1 == :accepted))
    |> Enum.count()
    |> then(&if &1 >= needed, do: :ok, else: {:error, :not_accepted})
  end
end
