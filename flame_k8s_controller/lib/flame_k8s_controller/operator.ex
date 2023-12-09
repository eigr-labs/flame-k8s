defmodule FlameK8sController.Operator do
  @moduledoc """
  Defines the operator.

  The operator resource defines custom resources, watch queries and their
  controllers and serves as the entry point to the watching and handling
  processes.
  """

  use Bonny.Operator, default_watch_namespace: "default"

  step(Bonny.Pluggable.Logger, level: :info)
  step(:delegate_to_controller)
  step(Bonny.Pluggable.ApplyStatus)
  step(Bonny.Pluggable.ApplyDescendants)

  @impl Bonny.Operator
  def controllers(_watching_namespace, _opts) do
    []
  end

  @impl Bonny.Operator
  def crds() do
    []
  end
end
