defmodule Espresso do
  defmacro __using__(_opts) do
    quote do
      import Espresso
      import Plug.Conn
      @behaviour Plug

      Module.register_attribute(__MODULE__, :routes, accumulate: true)
      Module.register_attribute(__MODULE__, :middlewares, accumulate: true)

      def init(opts), do: opts

      # We use var!(conn) here to start the context
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

  defmacro use_middleware(plug_mod, opts \\ []) do
    quote do: @middlewares {unquote(plug_mod), unquote(opts)}
  end

  defmacro get(path, do: block), do: define_route("GET", path, block)
  defmacro post(path, do: block), do: define_route("POST", path, block)

  defp define_route(method, path, block) do
    segments =
      path
      |> String.split("/", trim: true)
      |> Enum.map(fn
        ":" <> var -> String.to_atom(var)
        literal -> literal
      end)

    quote do
      @routes {unquote(method), unquote(segments), unquote(Macro.escape(block))}
    end
  end

  defmacro __before_compile__(env) do
    routes = Module.get_attribute(env.module, :routes)
    middlewares = Module.get_attribute(env.module, :middlewares) |> Enum.reverse()

    # We wrap 'conn' in var!() so it can be updated by middlewares
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
