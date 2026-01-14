defmodule KV do
  @moduledoc """
  Documentation for `KV`.
  """

  use Application

  @impl true
  def start(_type, _args) do
    for node <- Application.fetch_env!(:kv, :nodes) do
      Node.connect(node)
    end

    port = Application.fetch_env!(:kv, :port)

    children = [
      {Registry, name: KV, keys: :unique},
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {Task.Supervisor, name: KV.ServerSupervisor},
      Supervisor.child_spec({Task, fn -> KV.Server.accept(port) end}, restart: :permanent)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Creates a bucket with the given name.
  """
  def create_bucket(name) do
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

  defp via(name), do: {:via, :global, {KV, name}}
end
