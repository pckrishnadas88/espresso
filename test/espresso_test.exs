defmodule EspressoTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  # Define a test server inside the test file
  defmodule TestServer do
    use Espresso

    scope "/api" do
      get "/users/:id" do
        send_resp(conn, 200, "User ID: #{id}")
      end
    end

    post "/echo" do
      send_resp(conn, 201, "Created")
    end
  end

  test "GET /api/users/:id extracts parameters" do
    # Build a fake connection
    conn = conn(:get, "/api/users/42")

    # Call the server
    conn = TestServer.call(conn, [])

    assert conn.status == 200
    assert conn.resp_body == "User ID: 42"
  end

  test "POST /echo returns 201" do
    conn = conn(:post, "/echo", %{})
    conn = TestServer.call(conn, [])

    assert conn.status == 201
  end

  test "Undefined route returns 404" do
    conn = conn(:get, "/not_found")
    conn = TestServer.call(conn, [])

    assert conn.status == 404
  end
end
