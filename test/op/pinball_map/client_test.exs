defmodule OP.PinballMap.ClientTest do
  use ExUnit.Case, async: false

  alias OP.PinballMap.Client
  alias OP.PinballMap.Errors.ApiError

  import OP.PinballMapFixtures

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "new/1" do
    test "creates client with default values" do
      client = Client.new()

      assert client.base_url == "https://pinballmap.com/api/v1"
      assert client.timeout == 30_000
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

  describe "get_region_locations/2" do
    test "returns locations on 200 response with wrapped format" do
      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, region_locations_response())
      end)

      client = Client.new()
      assert {:ok, locations} = Client.get_region_locations(client, "portland")
      assert length(locations) == 2
      assert hd(locations)["name"] == "Ground Kontrol"
    end

    test "returns locations on 200 response with unwrapped format" do
      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, default_locations())
      end)

      client = Client.new()
      assert {:ok, locations} = Client.get_region_locations(client, "portland")
      assert length(locations) == 2
    end

    test "returns empty list when region has no locations" do
      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => []})
      end)

      client = Client.new()
      assert {:ok, []} = Client.get_region_locations(client, "empty-region")
    end

    test "returns ApiError for 404 response" do
      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Plug.Conn.send_resp(conn, 404, "")
      end)

      client = Client.new()

      assert {:error, %ApiError{status_code: 404}} =
               Client.get_region_locations(client, "unknown")
    end

    test "returns ApiError for 500 response" do
      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, Jason.encode!(%{"error" => "Internal server error"}))
      end)

      client = Client.new()

      assert {:error, %ApiError{status_code: 500}} =
               Client.get_region_locations(client, "portland")
    end
  end
end
