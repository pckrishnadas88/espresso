# Espresso web ☕

**Espresso web** is a lightweight, high-performance web framework for Elixir, inspired by the ergonomics of Express.js.

Unlike traditional frameworks that resolve routes at runtime, Espresso uses **Metaprogramming** to compile your routes directly into native Elixir function headers. This results in **O(1) routing speed** and minimal memory overhead, leveraging the full power of the BEAM virtual machine.

## Key Features

* **Express-style DSL**: Familiar `get`, `post`, `put`, `patch`, and `delete` macros.
* **Compile-Time Routing**: Routes are transformed into pattern-matched function clauses.
* **Dynamic Path Parameters**: Simple syntax for variables (e.g., `/users/:id`).
* **Middleware Pipeline**: Easily plug in standard `Plug` modules or custom logic.
* **Zero-Boilerplate**: Start a web server in a single file.

---

## Installation

Add `espresso` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:espresso_web, "~> 0.1.0"},
    {:plug_cowboy, "~> 2.7"},
    {:jason, "~> 1.4"}
  ]
end

```

---

## Quick Start

Building an API with Espresso is straightforward. Define your routes and start the listener:

```elixir
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

# To start the server:
# MyApp.listen(4000)

```

---

## Architecture: Why Espresso Web?

Most web frameworks store routes in a list and iterate through them for every request. Espresso Web is different.

When you write a route in Espresso Web, the **Macro Engine** performs a "Code Merge." It takes your logic and injects it into a private dispatch function. At runtime, the BEAM uses its highly optimized pattern matching to jump directly to the correct code block.

### Pipeline Flow

1. **Request** enters via Cowboy/Bandit.
2. **Middlewares** are executed in sequence (the `conn` is passed through).
3. **Halt Check**: If a middleware halts the connection (e.g., Auth failure), the pipeline stops.
4. **Dispatch**: The request matches a compiled function based on Method and Path.

---

## Current Status (v0.1.0)

This project is currently a **Proof of Concept**.

* [x] Basic HTTP Verbs
* [x] Middleware Support
* [x] Dynamic Path Segments
* [x] Scoped Routes (Planned)
* [ ] Built-in Error Handling (Planned)

## License

MIT

---

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `espresso_web` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:espresso_web, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/espresso_web>.

