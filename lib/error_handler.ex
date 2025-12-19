defmodule EspressoWeb.ErrorHandler do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    try do
      # This plug doesn't DO anything yet, it just "passes through"
      # but stays "alive" to catch crashes from plugs that come AFTER it.
      conn
    rescue
      e ->
        handle_error(conn, e)
    end
  end

  defp handle_error(conn, _error) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(500, Jason.encode!(%{error: "Internal Server Error"}))
    # Stop the pipeline immediately
    |> halt()
  end
end
