defmodule FlameK8sController.Webhooks.MutatingControlHandler do
  @moduledoc """
  Mutating Webhook Handler for Postgres Kompo
  """
  use K8sWebhoox.AdmissionControl.Handler

  alias K8sWebhoox.Conn

  import K8sWebhoox.AdmissionControl.AdmissionReview

  mutate "apps/v1/deployments", conn do
    %Conn{
      request: request
    } = conn

    %{"object" => %{"spec" => spec}} = request

    metadata = Map.get(spec, "template", %{})["metadata"]

    resp =
      if is_flame_enabled?(metadata) do
        create_patch(conn, patch_obj(spec))
      else
        conn
      end

    allow(resp)
  end

  mutate "apps/v1/statefulsets", conn do
    %Conn{
      request: _request,
      response: _response
    } = conn

    allow(conn)
  end

  defp is_flame_enabled?(metadata) do
    annotations = Map.get(metadata, "annotations", %{})
    Map.get(annotations, "flame-eigr.io/enabled", "false") |> to_bool()
  end

  defp patch_obj(spec) do
    container =
      spec
      |> Map.get("template", %{})
      |> Map.get("spec", %{})
      |> Map.get("containers", [])
      |> List.first()

    base_pod =
      Jason.encode!(spec.template)
      |> Base.encode64()

    envs = [
      %{"name" => "BASE_POD", "value" => base_pod},
      %{"name" => "POD_NAME", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}},
      %{
        "name" => "POD_NAMESPACE",
        "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
      },
      %{"name" => "POD_IP", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}}
    ]

    updated_envs =
      case Map.get(container, "env") do
        nil ->
          %{
            "op" => "add",
            "path" => "/spec/template/spec/containers/0",
            "value" => %{"env" => envs}
          }

        existing_envs ->
          %{
            "op" => "replace",
            "path" => "/spec/template/spec/containers/0/env",
            "value" => existing_envs ++ envs
          }
      end

    [updated_envs]
    |> Jason.encode!()
    |> Base.encode64()
  end

  defp create_patch(conn, patch_obj) do
    %Conn{conn | response: %{conn.response | patch: patch_obj, patchType: "JSONPatch"}}
  end

  def to_bool("true"), do: true
  def to_bool("false"), do: false
  def to_bool(_), do: false
end
