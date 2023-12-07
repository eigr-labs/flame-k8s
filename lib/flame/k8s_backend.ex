defmodule FLAME.K8sBackend do
  @moduledoc """
  The `FLAME.Backend` using [Kubernetes](https://kubernetes.io/) system.
  """
  @behaviour FLAME.Backend

  alias FLAME.K8sBackend

  @derive {Inspect,
           only: [
             :namespace,
             :image,
             :app
           ]}
  defstruct namespace: nil,
            image: nil,
            app: nil

  @impl true
  def init(_opts) do
    {:ok, %K8sBackend{}}
  end

  @impl true
  def remote_spawn_monitor(%K8sBackend{} = _state, _term) do
    {:ok, {nil, nil}}
  end

  @impl true
  def system_shutdown do
    System.stop()
  end

  @impl true
  def remote_boot(%K8sBackend{} = state) do
    {:ok, nil, state}
  end

  @impl true
  def handle_info({:nodedown, _down_node}, state) do
    {:noreply, state}
  end

  def handle_info({:nodeup, _}, state), do: {:noreply, state}

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
