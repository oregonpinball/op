defmodule OP.Matchplay.ClientTest do
  use ExUnit.Case, async: true

  alias OP.Matchplay.Client
  alias OP.Matchplay.Errors.{ApiError, NotFoundError}

  import OP.MatchplayFixtures

  setup do
    Req.Test.set_req_test_from_context(__MODULE__)
    :ok
  end

  describe "new/1" do
    test "creates client with default values" do
      client = Client.new()

      assert client.base_url == "https://app.matchplay.events/api"
      assert client.timeout == 30_000
    end

    test "creates client with custom api_token" do
      client = Client.new(api_token: "test-token")

      assert client.api_token == "test-token"
    end

    test "creates client with custom base_url" do
      client = Client.new(base_url: "https://custom.api.com")

      assert client.base_url == "https://custom.api.com"
    end

    test "creates client with custom timeout" do
      client = Client.new(timeout: 60_000)

      assert client.timeout == 60_000
    end
  end

  describe "get_tournament/2" do
    test "returns tournament data on 200 response" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Req.Test.json(conn, %{
          "data" => tournament_response(%{"tournamentId" => 12345})
        })
      end)

      client = Client.new(api_token: "test-token")
      assert {:ok, data} = Client.get_tournament(client, 12345)
      assert data["tournamentId"] == 12345
      assert data["name"] == "Test Tournament"
    end

    test "extracts data from wrapped response" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Req.Test.json(conn, %{
          "data" => %{"tournamentId" => 99999, "name" => "Wrapped Tournament"}
        })
      end)

      client = Client.new(api_token: "test-token")
      assert {:ok, data} = Client.get_tournament(client, 99999)
      assert data["name"] == "Wrapped Tournament"
    end

    test "handles unwrapped response body" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Req.Test.json(conn, %{"tournamentId" => 88888, "name" => "Unwrapped"})
      end)

      client = Client.new(api_token: "test-token")
      assert {:ok, data} = Client.get_tournament(client, 88888)
      assert data["name"] == "Unwrapped"
    end

    test "returns NotFoundError for 404 response" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Plug.Conn.send_resp(conn, 404, "")
      end)

      client = Client.new(api_token: "test-token")
      assert {:error, %NotFoundError{resource_id: "12345"}} = Client.get_tournament(client, 12345)
    end

    test "returns ApiError for 500 response" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, Jason.encode!(%{"error" => "Internal server error"}))
      end)

      client = Client.new(api_token: "test-token")
      assert {:error, %ApiError{status_code: 500}} = Client.get_tournament(client, 12345)
    end

    test "returns ApiError for 403 response" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(403, Jason.encode!(%{"error" => "Forbidden"}))
      end)

      client = Client.new(api_token: "test-token")
      assert {:error, %ApiError{status_code: 403}} = Client.get_tournament(client, 12345)
    end
  end

  describe "get_standings/2" do
    test "returns standings array on success" do
      standings = standings_response()

      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Req.Test.json(conn, standings)
      end)

      client = Client.new(api_token: "test-token")
      assert {:ok, data} = Client.get_standings(client, 12345)
      assert is_list(data)
      assert length(data) == 3
      assert hd(data)["name"] == "Alice Smith"
    end

    test "returns NotFoundError for 404 response" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Plug.Conn.send_resp(conn, 404, "")
      end)

      client = Client.new(api_token: "test-token")

      assert {:error, %NotFoundError{resource_id: "standings"}} =
               Client.get_standings(client, 12345)
    end

    test "returns empty array when tournament has no standings" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        Req.Test.json(conn, [])
      end)

      client = Client.new(api_token: "test-token")
      assert {:ok, []} = Client.get_standings(client, 12345)
    end
  end

  describe "authorization header" do
    test "includes authorization header when api_token is set" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        auth_header = Plug.Conn.get_req_header(conn, "authorization")
        assert auth_header == ["Bearer my-token"]
        Req.Test.json(conn, %{"data" => %{}})
      end)

      client = Client.new(api_token: "my-token")
      Client.get_tournament(client, 12345)
    end

    test "omits authorization header when api_token is nil" do
      Req.Test.stub(OP.Matchplay.Client, fn conn ->
        auth_header = Plug.Conn.get_req_header(conn, "authorization")
        assert auth_header == []
        Req.Test.json(conn, %{"data" => %{}})
      end)

      client = Client.new(api_token: nil)
      Client.get_tournament(client, 12345)
    end
  end
end
