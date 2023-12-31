defmodule FlameK8sController.Handler.FlameRunnerHandler do
  @moduledoc """

  ---
  apiVersion: flame.org/v1
  kind: FlameRunner
  metadata:
    name: my-runner
    namespace: default
  spec:
    image: docker.io/eigr/flame-examples:latest
    runnerPoolFromConfigRef: my-runner-pool
  """

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
      |> Pod.manifest()

    axn
    |> Bonny.Axn.register_descendant(pod_resource)
    |> Bonny.Axn.success_event()
  end

  @impl Pluggable
  def call(%Bonny.Axn{action: action} = axn, nil) when action in [:delete, :reconcile] do
    Bonny.Axn.success_event(axn)
  end
end
