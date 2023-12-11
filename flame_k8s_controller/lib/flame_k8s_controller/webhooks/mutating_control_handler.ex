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

    resp =
      if op == "CREATE" do
        patch_obj =
          [
            %{
              "op" => "replace",
              "path" => "/spec/containers/0/env",
              "value" => %{}
            }
          ]
          |> Jason.encode()
          |> Base.decode64!()

        %Conn{
          conn
          | response: %{response | patch: patch_obj, patchType: "JSONPatch"}
        }
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
end
