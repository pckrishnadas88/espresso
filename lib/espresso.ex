defmodule Espresso do
  @version "0.1.0"

  def version, do: @version

  defmacro __using__(_opts) do
    quote do
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

      def status(var!(conn), code), do: %{var!(conn) | status: code}

      def send(var!(conn), body) do
        send_resp(var!(conn), var!(conn).status || 200, body)
      end

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

  # ... (Keep scope, use_middleware, and verbs the same) ...
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

  defmacro get(path, do: block), do: define_route("GET", path, block)
  defmacro post(path, do: block), do: define_route("POST", path, block)
  defmacro put(path, do: block), do: define_route("PUT", path, block)
  defmacro patch(path, do: block), do: define_route("PATCH", path, block)
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
