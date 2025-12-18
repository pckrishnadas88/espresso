defmodule EspressoTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  # Define a test server using the new "Beautiful" syntax
  defmodule TestServer do
    use Espresso

    scope "/api" do
      # Testing the 'json' helper and dynamic params
      get "/users/:id" do
        conn
        |> status(200)
        |> json(%{user_id: id, message: "Fetched"})
      end

      # Testing the 'send' helper
      get "/ping" do
        conn |> send("pong")
      end
    end

    # Testing POST with status helper
    post "/create" do
      conn
      |> status(201)
      |> json(%{status: "created"})
    end
  end

  test "GET /api/ping returns plain text using send/2" do
    conn = conn(:get, "/api/ping")
    conn = TestServer.call(conn, [])

    assert conn.status == 200
    assert conn.resp_body == "pong"
  end

  test "GET /api/users/:id returns JSON and sets headers" do
    conn = conn(:get, "/api/users/123")
    conn = TestServer.call(conn, [])

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

    # Decode response to verify logic
    body = Jason.decode!(conn.resp_body)
    assert body["user_id"] == "123"
    assert body["message"] == "Fetched"
  end

  test "POST /create returns 201 using status/2 and json/2" do
    conn = conn(:post, "/create")
    conn = TestServer.call(conn, [])

    assert conn.status == 201
    assert Jason.decode!(conn.resp_body)["status"] == "created"
  end

  test "404 handler still works" do
    conn = conn(:get, "/undefined/path")
    conn = TestServer.call(conn, [])

    assert conn.status == 404
  end
end
