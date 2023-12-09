defmodule FlameK8sController.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)

  forward("/health", to: FlameK8sController.Routes.Health)

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
