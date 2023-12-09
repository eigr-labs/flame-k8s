defmodule FlameK8sController.Application do
  @moduledoc false
  use Application

  require Logger

  @port 9090

  def start(_type, args) do
    env = Keyword.get(args, :env, :dev)
    opts = [strategy: :one_for_one, name: FlameK8sController.Supervisor]
    Supervisor.start_link(children(env), opts)
  end

  defp children(:test), do: []

  defp children(env) do
    [
      {FlameK8sController.Operator,
       conn: FlameK8sController.K8sConn.get!(env), enable_leader_election: true},
      {Bandit, plug: FlameK8sController.Router, scheme: :http, port: @port}
    ]
  end
end
