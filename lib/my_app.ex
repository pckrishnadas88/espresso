defmodule MyApp do
  use Espresso

  # Middleware for JSON, form-data, urlencode parsing
  use_middleware Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  # Enable logger middleware for request logging
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

# --- NEW: The Application Supervisor ---
defmodule MyApp.Application do
  use Application

  @doc """
  This starts your app as a supervised process.
  If the web server crashes, the Supervisor will restart it instantly.
  """
  def start(_type, _args) do
    children = [
      # We use Plug.Cowboy.child_spec to define the worker
      {Plug.Cowboy, scheme: :http, plug: MyApp, options: [port: 4000]}
    ]

    # :one_for_one = If a process dies, restart only that process.
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]

    IO.puts "🛡️  Supervision Tree started. Watching MyApp..."
    Supervisor.start_link(children, opts)
  end
end
