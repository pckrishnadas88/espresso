defmodule Espresso do
  @moduledoc """
  Espresso is a minimal, high-performance web framework for Elixir.

  It uses metaprogramming to compile your routes into highly optimized pattern-matching
  functions, providing a developer experience similar to Express.js but with the
  fault-tolerance and speed of the Erlang VM (BEAM).
  """
  @version "0.1.0"

  def version, do: @version

  @doc """
  Sets up the module to use Espresso.

  When you `use Espresso`, it:
  1. Imports `Espresso` and `Plug.Conn` functions.
  2. Sets up the route tracking system.
  3. Prepares the module for the `@before_compile` hook.
  """

  defmacro __using__(_opts) do
    quote do
      @doc "Sets the HTTP response status code."
      # This line is the fix: it stops the conflict with Elixir's built-in send
      import Kernel, except: [send: 2]
      import Espresso
      import Plug.Conn
      @behaviour Plug

      Module.register_attribute(__MODULE__, :routes, accumulate: true)
      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)
      Module.put_attribute(__MODULE__, :path_prefix, "")

      def init(opts), do: opts
      def call(var!(conn), _opts), do: execute_pipeline(var!(conn))

      @doc """
      Sets the HTTP status code for the response.

      ## Examples
          conn |> status(404) |> send("Not Found")
      """
      def status(var!(conn), code), do: %{var!(conn) | status: code}

      @doc """
      Sends a plain text response.

      ## Examples
          conn |> send("Hello World")
      """
      def send(var!(conn), body) do
        send_resp(var!(conn), var!(conn).status || 200, body)
      end

      @doc """
      Sends a JSON response.

      Automatically encodes the data using `Jason` and sets the `content-type`
      header to `application/json`.
      """
      def json(var!(conn), data) do
        var!(conn)
        |> put_resp_content_type("application/json")
        |> send_resp(var!(conn).status || 200, Jason.encode!(data))
      end

      def listen(port \\ 4000) do
        IO.puts("🚀 Espresso serving on http://localhost:#{port}")
        Plug.Cowboy.http(__MODULE__, [], port: port)
      end

      @before_compile Espresso
    end
  end

  @doc """
  Groups routes under a specific path prefix.

  Useful for versioning APIs or grouping related resources.

  ## Examples
      scope "/api/v1" do
        get "/users" do
          # logic
        end
      end
  """
  defmacro scope(path, do: block) do
    quote do
      old_prefix = Module.get_attribute(__MODULE__, :path_prefix)
      Module.put_attribute(__MODULE__, :path_prefix, old_prefix <> unquote(path))
      unquote(block)
      Module.put_attribute(__MODULE__, :path_prefix, old_prefix)
    end
  end

  defmacro use_middleware(plug_mod, opts \\ []),
    do: quote(do: @middlewares({unquote(plug_mod), unquote(opts)}))

  @doc """
  Defines a GET route.

  Takes a `path` string and a `do` block. The block has access to a `conn`
  variable representing the connection.

  ## Examples
      get "/ping" do
        conn |> send_resp(200, "pong")
      end
  """
  defmacro get(path, do: block), do: define_route("GET", path, block)

  @doc """
  Defines a POST route.

  Commonly used for creating resources or handling form submissions.
  """
  defmacro post(path, do: block), do: define_route("POST", path, block)
  defmacro put(path, do: block), do: define_route("PUT", path, block)
  defmacro patch(path, do: block), do: define_route("PATCH", path, block)

  @doc """
  Defines a DELETE route.
  Used for removing resources. Returns a connection.
  """
  defmacro delete(path, do: block), do: define_route("DELETE", path, block)

  defp define_route(method, path, block) do
    quote do
      full_path = Module.get_attribute(__MODULE__, :path_prefix) <> unquote(path)

      segments =
        full_path
        |> String.split("/", trim: true)
        |> Enum.map(fn
          ":" <> var -> String.to_atom(var)
          literal -> literal
        end)

      @routes {unquote(method), segments, unquote(Macro.escape(block))}
    end
  end

  defmacro __before_compile__(env) do
    routes = Module.get_attribute(env.module, :routes)
    middlewares = Module.get_attribute(env.module, :middlewares) |> Enum.reverse()

    mw_logic =
      for {p, o} <- middlewares,
          do: quote(do: var!(conn) = unquote(p).call(var!(conn), unquote(p).init(unquote(o))))

    handlers =
      for {method, segments, block} <- routes do
        args =
          Enum.map(segments, fn
            s when is_atom(s) -> quote do: var!(unquote({s, [], nil}))
            s -> s
          end)

        # FIX: Added parentheses to solve the ambiguity warning
        quote do
          defp dispatch(var!(conn), unquote(method), unquote(args)) do
            unquote(block)
          end
        end
      end

    quote do
      defp execute_pipeline(var!(conn)) do
        unquote_splicing(mw_logic)

        if !var!(conn).halted,
          do: dispatch(var!(conn), var!(conn).method, var!(conn).path_info),
          else: var!(conn)
      end

      unquote(handlers)
      defp dispatch(conn, _, _), do: send_resp(conn, 404, "Not Found")
    end
  end
end
