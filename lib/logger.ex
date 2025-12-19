defmodule EspressoWeb.Logger do
  import Plug.Conn
  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time()

    # We register a "before_send" hook because the response
    # hasn't been sent yet when this function runs.
    register_before_send(conn, fn conn ->
      stop_time = System.monotonic_time()
      duration = System.convert_time_unit(stop_time - start_time, :native, :microsecond)

      Logger.info("""
      --- Incoming Request ---
      Method: #{conn.method}
      Path:   #{conn.request_path}
      Status: #{conn.status}
      Time:   #{duration}µs
      ------------------------
      """)

      conn
    end)
  end
end
