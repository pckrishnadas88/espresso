defmodule MyApp do
  use Espresso

  # Middlewares
  use_middleware Plug.Parsers, parsers: [:json], json_decoder: Jason

  # Global routes
  get "/" do
    send_resp(conn, 200, "Espresso Root")
  end

  # Scoped API
  scope "/api/v1" do
    get "/users/:id" do
      send_resp(conn, 200, "GET User #{id}")
    end

    post "/users" do
      send_resp(conn, 201, "POST User Created")
    end

    put "/users/:id" do
      send_resp(conn, 200, "PUT User #{id} Updated")
    end

    patch "/users/:id" do
      send_resp(conn, 200, "PATCH User #{id} Partially Updated")
    end

    delete "/users/:id" do
      send_resp(conn, 200, "DELETE User #{id} Removed")
    end
  end
end
