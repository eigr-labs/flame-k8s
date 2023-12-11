defmodule FlameK8sController.K8s.Client do
  @moduledoc false

  @pod_tpl "/api/v1/namespaces/:namespace/pods/:name"
  @pod_list_tpl "/api/v1/namespaces/:namespace/pods"

  def connect(path_to_token, opts) do
    ca_cert_path = Path.join(path_to_token, "ca.crt")
    token_path = Path.join(path_to_token, "token")

    verify =
      if Keyword.get(opts, :insecure_skip_tls_verify, false),
        do: :verify_none,
        else: :verify_peer

    apiserver_host = System.get_env("KUBERNETES_SERVICE_HOST")
    apiserver_port = System.get_env("KUBERNETES_SERVICE_PORT")

    with {:ok, token} <- File.read(token_path),
         {:ok, ca_cert_raw} <- File.read(ca_cert_path),
         {:ok, ca_cert} <- cert_from_pem(ca_cert_raw) do
      req =
        Req.new(
          base_url: "https://#{apiserver_host}:#{apiserver_port}",
          headers: [{:Authorization, "Bearer #{token}"}],
          connect_options: [transport_opts: [cacerts: [ca_cert], verify: verify]]
        )
        |> Req.Request.append_response_steps(verify_2xs: &verify_2xs/1)

      {:ok, req}
    else
      error -> error
    end
  end

  def get_pod!(req, namespace, name) do
    Req.get!(req, url: @pod_tpl, path_params: [namespace: namespace, name: name]).body
  end

  def get_pod(req, namespace, name) do
    with {:ok, %{body: body}} <-
           Req.get(req, url: @pod_tpl, path_params: [namespace: namespace, name: name]),
         do: {:ok, body}
  end

  def delete_pod!(req, namespace, name) do
    Req.delete!(req, url: @pod_tpl, path_params: [namespace: namespace, name: name])
  end

  def create_pod!(req, pod, timeout) do
    name = pod["metadata"]["name"]
    namespace = pod["metadata"]["namespace"]
    Req.post!(req, url: @pod_list_tpl, path_params: [namespace: namespace], json: pod)
    wait_until_scheduled(req, namespace, name, timeout)
  end

  defp wait_until_scheduled(_req, _namespace, _name, timeout) when timeout <= 0, do: :error

  defp wait_until_scheduled(req, namespace, name, timeout) do
    case get_pod!(req, namespace, name) do
      %{"status" => %{"podIP" => _}} = pod ->
        {:ok, pod}

      _ ->
        Process.sleep(1000)
        wait_until_scheduled(req, namespace, name, timeout - 1000)
    end
  end

  defp cert_from_pem(cert_data) do
    cert_data
    |> :public_key.pem_decode()
    |> Enum.find_value(fn
      {:Certificate, data, _} ->
        {:ok, data}

      _ ->
        {:error, "Certificate data is missing"}
    end)
  end

  defp verify_2xs({request, response}) do
    if response.status in 200..299 do
      {request, response}
    else
      {request, RuntimeError.exception(response.body["message"])}
    end
  end
end
