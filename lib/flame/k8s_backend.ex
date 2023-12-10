defmodule FLAME.K8sBackend do
  @moduledoc """
  The `FLAME.Backend` using [Kubernetes](https://kubernetes.io/) system.
  """
  require Logger

  alias FLAME.K8sBackend

  @behaviour FLAME.Backend

  defstruct env: %{},
            parent_ref: nil,
            runner_node_basename: nil,
            runner_pod_ip: nil,
            runner_pod_name: nil,
            runner_node_name: nil,
            boot_timeout: nil,
            container_name: nil,
            remote_terminator_pid: nil,
            log: false

  @valid_opts ~w(container_name terminator_sup log)a
  @required_config ~w()a

  @impl true
  def init(opts) do
    :global_group.monitor_nodes(true)
    conf = Application.get_env(:flame, __MODULE__) || []
    [node_base | _ip] = node() |> to_string() |> String.split("@")

    default = %K8sBackend{
      boot_timeout: 30_000,
      runner_node_basename: node_base
    }

    provided_opts =
      conf
      |> Keyword.merge(opts)
      |> Keyword.validate!(@valid_opts)

    state = struct(default, provided_opts)

    for key <- @required_config do
      unless Map.get(state, key) do
        raise ArgumentError, "missing :#{key} config for #{inspect(__MODULE__)}"
      end
    end

    parent_ref = make_ref()

    encoded_parent =
      parent_ref
      |> FLAME.Parent.new(self(), __MODULE__)
      |> FLAME.Parent.encode()

    new_env =
      Map.merge(
        %{PHX_SERVER: "false", DRAGONFLY_PARENT: encoded_parent},
        state.env
      )

    initial_state = struct(state, env: new_env, parent_ref: parent_ref)

    {:ok, initial_state}
  end

  @impl true
  def remote_spawn_monitor(%K8sBackend{} = state, term) do
    case term do
      func when is_function(func, 0) ->
        {pid, ref} = Node.spawn_monitor(state.runner_node_name, func)
        {:ok, {pid, ref}}

      {mod, fun, args} when is_atom(mod) and is_atom(fun) and is_list(args) ->
        {pid, ref} = Node.spawn_monitor(state.runner_node_name, mod, fun, args)
        {:ok, {pid, ref}}

      other ->
        raise ArgumentError,
              "expected a null arity function or {mod, func, args}. Got: #{inspect(other)}"
    end
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
  def handle_info({:nodedown, down_node}, state) do
    if down_node == state.runner_node_name do
      log(state, "Runner #{state.runner_node_name} Down")
      {:stop, {:shutdown, :noconnection}, state}
    else
      log(state, "Other Runner #{down_node} Down")
      {:noreply, state}
    end
  end

  def handle_info({:nodeup, _}, state), do: {:noreply, state}

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def with_elapsed_ms(func) when is_function(func, 0) do
    {micro, result} = :timer.tc(func)
    {result, div(micro, 1000)}
  end

  defp connect_to_node(_node_name, timeout) when timeout <= 0 do
    :error
  end

  defp connect_to_node(node_name, timeout) do
    if Node.connect(node_name) do
      :ok
    else
      Process.sleep(1000)
      connect_to_node(node_name, timeout - 1000)
    end
  end

  defp rand_id(len) do
    len
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(padding: false, case: :lower)
    |> binary_part(0, len)
  end

  defp encode_k8s_env(env_map) do
    for {name, value} <- env_map, do: %{"name" => name, "value" => value}
  end

  defp log(%K8sBackend{log: false}, _), do: :ok

  defp log(%K8sBackend{log: level}, msg, metadata \\ []) do
    Logger.log(level, msg, metadata)
  end
end
