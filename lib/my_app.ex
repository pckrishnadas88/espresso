defmodule MyApp do
  use EspressoWeb

  # Middleware for JSON, form-data, urlencode parsing
  use_middleware(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  # Enable logger middleware for request logging
  use_middleware(EspressoWeb.Logger)

  # health check route
  get "/health" do
    # Get the system uptime in milliseconds
    {uptime, _} = :erlang.statistics(:wall_clock)

    conn
    |> status(200)
    |> json(%{
      status: "UP",
      uptime_ms: uptime,
      version: "1.0.0"
    })
  end

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
      users = [
        %{id: "1", name: "Jose"},
        %{id: "2", name: "Chris"},
        %{id: "3", name: "You"}
      ]

      Enum.reject(users, fn user -> user.id == id end)
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
    # 1. Look for an environment variable named "PORT"
    # 2. If it's nil, default to "4000"
    # 3. Convert the string to an integer (Cowboy needs an integer)
    port_string = System.get_env("PORT") || "4000"
    port = String.to_integer(port_string)

    children = [
      # We use Plug.Cowboy.child_spec to define the worker
      {Plug.Cowboy, scheme: :http, plug: MyApp, options: [port: port]}
    ]

    # :one_for_one = If a process dies, restart only that process.
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]

    IO.puts("🛡️  Espresso running on port #{port}")
    Supervisor.start_link(children, opts)
  end
end
