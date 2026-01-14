defmodule KV.Bucket do
  use GenServer

  @doc """
  Starts a new bucket.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    GenServer.call(bucket, {:get, key})
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    GenServer.call(bucket, {:put, key, value})
  end

  @doc """
  Get keys count of a bucket
  """
  def count_keys(bucket) do
    GenServer.call(bucket, {:count_keys})
  end

  @doc """
  Delete the `value` for the given `key` in the `bucket` and return `value`
  """
  def delete(bucket, key) do
    GenServer.call(bucket, {:delete, key})
  end

  @doc """
  Subscribes the current process to the bucket.
  """
  def subscribe(bucket) do
    GenServer.cast(bucket, {:subscribe, self()})
  end

  @doc """
  Get connection count subscribed to bucket
  """
  def count_connections(bucket) do
    GenServer.call(bucket, {:count_connections})
  end

  ### Callbacks

  @impl true
  def init(bucket) do
    state = %{bucket: bucket, subscribers: MapSet.new()}

    {:ok, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = get_in(state.bucket[key])
    {:reply, value, state}
  end

  def handle_call({:put, key, value}, _from, state) do
    state = put_in(state.bucket[key], value)
    broadcast(state, {:put, key, value})
    {:reply, :ok, state}
  end

  def handle_call({:count_keys}, _from, state) do
    key_size = state.bucket |> map_size()
    {:reply, key_size, state}
  end

  def handle_call({:delete, key}, _from, state) do
    {value, state} = pop_in(state.bucket[key])
    broadcast(state, {:delete, key})
    {:reply, value, state}
  end

  def handle_call({:count_connections}, _from, state) do
    subbscriber_size = state.subscribers |> MapSet.size()
    {:reply, subbscriber_size, state}
  end

  defp broadcast(state, message) do
    for pid <- state.subscribers do
      send(pid, message)
    end
  end

  @impl true
  def handle_cast({:subscribe, pid}, state) do
    Process.monitor(pid)
    state = update_in(state.subscribers, &MapSet.put(&1, pid))
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, _type, pid, _reason}, state) do
    state = update_in(state.subscribers, &MapSet.delete(&1, pid))
    {:noreply, state}
  end
end
