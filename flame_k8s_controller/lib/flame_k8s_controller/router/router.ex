defmodule FlameK8sController.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  forward("/health", to: FlameK8sController.Routes.Health)

  post("/admission-review/mutating",
    to: K8sWebhoox.Plug,
    init_opts: [
      webhook_handler:
        {FlameK8sController.Webhooks.MutatingControlHandler, webhook_type: :mutating}
    ]
  )

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
