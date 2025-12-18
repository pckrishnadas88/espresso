defmodule Espresso do
  defmacro __using__(_opts) do
    quote do
      import Espresso
      import Plug.Conn
      @behaviour Plug

      Module.register_attribute(__MODULE__, :routes, accumulate: true)
      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)

      # Track current scope prefix during compilation
      Module.put_attribute(__MODULE__, :path_prefix, "")

      def init(opts), do: opts

      def call(var!(conn), _opts) do
        execute_pipeline(var!(conn))
      end

      def listen(port \\ 4000) do
        IO.puts "🚀 Espresso serving on http://localhost:#{port}"
        Plug.Cowboy.http(__MODULE__, [], port: port)
      end

      @before_compile Espresso
    end
  end

  # --- Scope Macro ---
  defmacro scope(path, do: block) do
    quote do
      old_prefix = Module.get_attribute(__MODULE__, :path_prefix)
      new_prefix = old_prefix <> unquote(path)
      Module.put_attribute(__MODULE__, :path_prefix, new_prefix)

      unquote(block)

      Module.put_attribute(__MODULE__, :path_prefix, old_prefix)
    end
  end

  # --- Middleware Macro ---
  defmacro use_middleware(plug_mod, opts \\ []) do
    quote do: @middlewares {unquote(plug_mod), unquote(opts)}
  end

  # --- All HTTP Verbs ---
  defmacro get(path, do: block), do: define_route("GET", path, block)
  defmacro post(path, do: block), do: define_route("POST", path, block)
  defmacro put(path, do: block), do: define_route("PUT", path, block)
  defmacro patch(path, do: block), do: define_route("PATCH", path, block)
  defmacro delete(path, do: block), do: define_route("DELETE", path, block)

  defp define_route(method, path, block) do
    quote do
      # Merge prefix + path
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

  # --- The Code Merger (Generator) ---
  defmacro __before_compile__(env) do
    routes = Module.get_attribute(env.module, :routes)
    middlewares = Module.get_attribute(env.module, :middlewares) |> Enum.reverse()

    middleware_calls = for {plug, opts} <- middlewares do
      quote do
        var!(conn) = unquote(plug).call(var!(conn), unquote(plug).init(unquote(opts)))
      end
    end

    route_handlers = for {method, segments, block} <- routes do
      args = Enum.map(segments, fn
        s when is_atom(s) -> quote do: var!(unquote({s, [], nil}))
        s -> s
      end)

      quote do
        defp dispatch(var!(conn), unquote(method), unquote(args)) do
          unquote(block)
        end
      end
    end

    quote do
      defp execute_pipeline(var!(conn)) do
        unquote_splicing(middleware_calls)

        if !var!(conn).halted do
          dispatch(var!(conn), var!(conn).method, var!(conn).path_info)
        else
          var!(conn)
        end
      end

      unquote(route_handlers)
      defp dispatch(conn, _, _), do: send_resp(conn, 404, "Not Found")
    end
  end
end
