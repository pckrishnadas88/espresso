defmodule MyApp do
  use Espresso

  # Middleware for JSON, form-data, urlencode parsing
  use_middleware Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  use_middleware Espresso.Logger

  # Root Route
  get "/" do
    conn |> send("Welcome to Espresso")
  end

  # Scoped API
  scope "/api/v1" do
    # GET with dynamic param
    get "/users/:id" do
      conn |> json(%{user_id: id, status: "active"})
    end

    # POST with JSON response
    post "/users" do
      # Accessing req.body via conn.body_params
      user_data = conn.body_params
      conn |> status(201) |> json(%{message: "User created", data: user_data})
    end

    # DELETE
    delete "/users/:id" do
      conn |> status(204) |> send("")
    end
  end
end
