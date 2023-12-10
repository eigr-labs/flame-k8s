defmodule FlameK8sController.Handler.FlameRunnerHandler do
  @moduledoc false

  alias FlameK8sController.K8s.HeadlessService
  alias FlameK8sController.Operator
  alias FlameK8sController.K8s.Pod

  @behaviour Pluggable

  @impl Pluggable
  def init(_opts), do: nil

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:add, :modify] do
    %Bonny.Axn{resource: resource} = axn

    pod_resource =
      Operator.get_args(resource)
      |> FlameK8sController.K8s.Pod.manifest()

    axn
    |> Bonny.Axn.register_descendant(pod_resource)
    |> Bonny.Axn.success_event()
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete, :reconcile] do
    Bonny.Axn.success_event(axn)
  end
end
