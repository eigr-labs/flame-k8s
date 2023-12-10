defmodule FlameK8sController.K8s.Pod do
  @moduledoc false

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
      "kind" => "Pod",
      "metadata" => %{
        "namespace" => ns,
        "name" => name
      },
      "spec" => %{
        "restartPolicy" => "Never",
        "containers" => [
          %{
            "image" => "todo",
            "name" => "todo",
            "resources" => %{},
            "env" => %{}
          }
        ]
      }
    }
  end
end
