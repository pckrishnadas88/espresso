defmodule MyApp do
  use Espresso

  # Middlewares
  use_middleware Plug.Parsers, parsers: [:json], json_decoder: Jason

  # Static Route
  get "/" do
    send_resp(conn, 200, "API Home")
  end

  # Dynamic Route with 1 parameter
  get "/users/:id" do
    # 'id' is available because the Macro pattern-matched it!
    response = %{user_id: id, message: "Fetched user #{id}"}
    send_resp(conn, 200, Jason.encode!(response))
  end

  # Complex Dynamic Route with 2 parameters
  get "/users/:user_id/posts/:post_id" do
    response = %{
      user: user_id,
      post: post_id,
      path: conn.request_path
    }
    send_resp(conn, 200, Jason.encode!(response))
  end

  # POST route
  post "/users" do
    name = conn.body_params["name"]
    send_resp(conn, 201, "User #{name} created")
  end
end
