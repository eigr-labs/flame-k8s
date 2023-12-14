defmodule FlameK8sController.Controller.FlameRunner do
  use Bonny.ControllerV2
  require Bonny.API.CRD

  step(Bonny.Pluggable.SkipObservedGenerations)
  step(FlameK8sController.Handler.FlameRunnerHandler)

  def rbac_rules() do
    [
      to_rbac_rule({"", "secrets", "*"}),
      to_rbac_rule({"", ["services", "configmaps"], "*"})
    ]
  end
end
