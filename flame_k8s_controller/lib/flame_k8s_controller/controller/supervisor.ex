defmodule FlameK8sController.Controller.Supervisor do
  @doc false
  use Supervisor

  @impl true
  def init(opts) do
    children = [
      {FlameK8sController.Operator, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end
end
