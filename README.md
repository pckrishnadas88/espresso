# Espresso ☕

**Espresso** is a lightweight, high-performance web framework for Elixir, inspired by the ergonomics of Express.js.

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
    {:espresso, path: "../espresso"}, # While in development
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

  # Register Middlewares
  use_middleware Plug.Parsers, parsers: [:json], json_decoder: Jason
  use_middleware Espresso.Logger # If you implemented the logger helper

  # Static Route
  get "/" do
    send_resp(conn, 200, "Welcome to Espresso!")
  end

  # Dynamic Route
  get "/users/:id" do
    # 'id' is automatically injected into this block by the macro
    send_resp(conn, 200, "Fetching data for user #{id}")
  end

  # JSON POST Route
  post "/echo" do
    send_resp(conn, 201, Jason.encode!(conn.body_params))
  end
end

# To start the server:
# MyApp.listen(4000)

```

---

## Architecture: Why Espresso?

Most web frameworks store routes in a list and iterate through them for every request. Espresso is different.

When you write a route in Espresso, the **Macro Engine** performs a "Code Merge." It takes your logic and injects it into a private dispatch function. At runtime, the BEAM uses its highly optimized pattern matching to jump directly to the correct code block.

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
* [ ] Scoped Routes (Planned)
* [ ] Built-in Error Handling (Planned)

## License

MIT

---

### Pro-Tip for your GitHub

Since you mentioned international migration, make sure your **commit history** is clean.

**Would you like me to show you how to write a `test` file now?** Adding a `test/espresso_test.exs` and mentioning it in the README (e.g., "Run `mix test` to verify") is the single best way to prove to a US/EU company that you write production-ready code.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `espresso` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:espresso, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/espresso>.

