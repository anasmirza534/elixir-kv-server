defmodule KV do
  @moduledoc """
  Documentation for `KV`.
  """

  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:kv, :port)
    nodes = Application.fetch_env!(:kv, :nodes)

    for node <- nodes do
      Node.connect(node)
    end

    children = [
      # start a registry called `KV`
      {Registry, name: KV, keys: :unique},

      # start a dynamic supervisor that manages `Bucket` processes
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},

      # start task supervisor that manages client `serve` process
      {Task.Supervisor, name: KV.ServerSupervisor},

      # finall start server entrypoint that handle incoming request
      Supervisor.child_spec({Task, fn -> KV.Server.accept(port) end}, restart: :permanent)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Creates a bucket with the given name.
  """
  def create_bucket(name) do
    # create and link new `Bucket` to dynamic supervisor
    DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.Bucket, name: via(name)})
  end

  @doc """
  Looks up the given bucket.
  """
  def lookup_bucket(name) do
    name
    |> via()
    |> GenServer.whereis()
  end

  # :global here is used for discovering process on distributed nodes
  defp via(name), do: {:via, :global, {KV, name}}
end
