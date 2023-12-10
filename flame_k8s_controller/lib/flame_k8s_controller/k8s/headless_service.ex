defmodule FlameK8sController.K8s.HeadlessService do
  @moduledoc false

  @ports [
    %{"name" => "epmd", "protocol" => "TCP", "port" => 4369, "targetPort" => "epmd"}
  ]

  def manifest(
        %{
          annotations: annotations,
          labels: labels,
          name: name,
          namespace: ns,
          metadata: _metadata,
          params: _spec
        } = _resource,
        _opts \\ []
      ) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => name,
        "namespace" => ns,
        "annotations" => annotations,
        "labels" => labels
      },
      "spec" => %{
        "clusterIP" => "None",
        "selector" => %{"actor-system" => name},
        "ports" => @ports
      }
    }
  end
end
