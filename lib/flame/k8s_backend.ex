defmodule FLAME.K8sBackend do
  @moduledoc """
  The `FLAME.Backend` using [Kubernetes](https://kubernetes.io/) system.
  """
  require Logger

  alias FLAME.K8sBackend

  @behaviour FLAME.Backend

  @controller_fqdn "flame-controller.flame.svc.cluster.local"
  @controller_port 9090

  defstruct base_pod: nil,
            boot_timeout: nil,
            container_name: nil,
            controller_fqdn: nil,
            controller_port: nil,
            env: %{},
            log: false,
            parent_ref: nil,
            remote_terminator_pid: nil,
            runner_node_name: nil,
            runner_node_basename: nil,
            runner_pod_ip: nil,
            runner_pod_name: nil

  @valid_opts ~w(container_name controller_fqdn controller_port terminator_sup log)a
  @required_config ~w()a

  @impl true
  def init(opts) do
    :global_group.monitor_nodes(true)
    conf = Application.get_env(:flame, __MODULE__) || []
    [node_base | _ip] = node() |> to_string() |> String.split("@")

    default = %K8sBackend{
      boot_timeout: 30_000,
      controller_fqdn: @controller_fqdn,
      controller_port: @controller_port,
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
        %{PHX_SERVER: "false", FLAME_PARENT: encoded_parent},
        state.env
      )

    base_pod =
      System.get_env("BASE_POD")
      |> Base.decode64!()
      |> Jason.decode!()

    initial_state =
      struct(state,
        base_pod: base_pod,
        env: new_env,
        parent_ref: parent_ref
      )

    {:ok, initial_state}
  end

  @impl true
  def remote_boot(%K8sBackend{parent_ref: parent_ref} = state) do
    log(state, "Remote Boot")

    {new_state, req_connect_time} =
      with_elapsed_ms(fn ->
        created_pod =
          state
          |> build_runner_pod_request()
          |> provision_runner()

        log(state, "Pod Created and Scheduled")

        case created_pod do
          {:ok, pod} ->
            log(state, "Pod Scheduled. IP: #{pod["status"]["podIP"]}")

            struct!(state,
              runner_pod_ip: pod["status"]["podIP"],
              runner_pod_name: pod["metadata"]["name"]
            )

          error ->
            Logger.error(
              "Failed to schedule runner pod within #{state.boot_timeout}ms. Details: #{inspect(error)}"
            )

            exit(:timeout)
        end
      end)

    remaining_connect_window = state.boot_timeout - req_connect_time
    runner_node_name = :"#{state.runner_node_basename}@#{new_state.runner_pod_ip}"

    log(state, "Waiting for Remote UP. Remaining: #{remaining_connect_window}")

    case loop_until_ok(fn -> Node.connect(runner_node_name) end, remaining_connect_window) do
      {:ok, _} -> log(state, "Application connected with Runner ")
      _ -> exit(:timeout)
    end

    remote_terminator_pid =
      receive do
        {^parent_ref, {:remote_up, remote_terminator_pid}} ->
          remote_terminator_pid
      after
        remaining_connect_window ->
          Logger.error("Failed to connect to runner pod within #{state.boot_timeout}ms")
          exit(:timeout)
      end

    new_state =
      struct!(new_state,
        remote_terminator_pid: remote_terminator_pid,
        runner_node_name: runner_node_name
      )

    {:ok, remote_terminator_pid, new_state}
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
  def system_shutdown() do
    case call_shutdown_runner() do
      {:ok, :ending} ->
        Logger.debug("POD cleaning scheduled successfully")
        System.stop()

      _ ->
        Logger.warning("Unable to schedule POD cleaning")
        System.stop()
    end
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

  def loop_until_ok(func, timeout \\ 30_000) do
    task = Task.async(fn -> do_loop(func, func.()) end)

    Task.await(task, timeout)
  end

  defp build_runner_pod_request(state) do
    %{base_pod: base_pod, env: env} = state

    pod_name_sliced = base_pod |> get_in(~w(metadata name)) |> String.slice(0..40)
    runner_pod_name = pod_name_sliced <> rand_id(20)

    container_access =
      case state.container_name do
        nil -> []
        name -> [Access.filter(&(&1["name"] == name))]
      end

    base_container = base_pod |> get_in(["spec", "containers" | container_access]) |> List.first()

    %{}
  end

  defp provision_runner(runner_req) do
    {:ok, %{}}
  end

  defp call_shutdown_runner() do
    name = System.get_env("POD_NAME")
    namespace = System.get_env("POD_NAMESPACE")
    time_limit_to_shoot_headhead = System.get_env("POD_TERMINATION_TIMEOUT")
    # TODO Send signal to controller to cleanup pod after terminationShutdownPeriod timeout
    # calling "/v1/runners/:namespace/:name" endpoint in the controller service
  end

  defp do_loop(_func, {:ok, term}), do: {:ok, term}

  defp do_loop(func, _resp) do
    do_loop(func, func.())
  rescue
    _ -> do_loop(func, func.())
  catch
    _ -> do_loop(func, func.())
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
