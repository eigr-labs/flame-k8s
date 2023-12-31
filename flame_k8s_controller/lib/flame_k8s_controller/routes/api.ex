defmodule FlameK8sController.Routes.Api do
  @moduledoc false
  use FlameK8sController.Routes.Base

  post "/v1/runners/:namespace/:name", do: &handle_create_runner_pod/1

  delete "/v1/runners/:namespace/:name", do: &handle_delete_runner_pod/1

  match _ do
    send_resp(conn, 404, "Not found!")
  end

  defp handle_create_runner_pod(conn) do
    name = conn.params["name"]
    namespace = conn.params["namespace"]
  end

  defp handle_delete_runner_pod(conn) do
    name = conn.params["name"]
    namespace = conn.params["namespace"]
  end
end
