defmodule FlameK8sController.Webhooks.MutatingControlHandler do
  @moduledoc """
  Mutating Webhook Handler for Postgres Kompo
  """
  use K8sWebhoox.AdmissionControl.Handler

  alias K8sWebhoox.Conn

  import K8sWebhoox.AdmissionControl.AdmissionReview

  mutate "apps/v1/deployments", conn do
    %Conn{
      request: request,
      response: response
    } = conn

    %{"operation" => op, "object" => %{"spec" => spec}} = request

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
    [
      %{
        "op" => "replace",
        "path" => "/spec/template/spec/containers/0/env",
        "value" => %{}
      }
    ]
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
