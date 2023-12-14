defmodule FlameK8sController.K8s.Pod do
  @moduledoc false

  def manifest(
        %{
          annotations: annotations,
          labels: labels,
          name: name,
          namespace: ns,
          metadata: _metadata,
          params: spec
        } = _resource,
        _opts \\ []
      ) do
    %{
      "apiVersion" => "v1",
      "kind" => "Pod",
      "metadata" => %{
        "namespace" => ns,
        "name" => name,
        "annotations" => annotations,
        "labels" => labels
      },
      "spec" => %{
        "restartPolicy" => "Never",
        "containers" => [
          %{
            "image" => spec.image,
            "name" => name,
            "resources" => spec.runnerTemplate.resources,
            "env" => spec.env
          }
        ]
      }
    }
  end
end
