defmodule OP.PinballMap.ImportTest do
  use OP.DataCase, async: false

  alias OP.PinballMap.Import
  alias OP.Locations
  alias OP.Accounts.Scope

  import OP.PinballMapFixtures

  setup do
    Req.Test.verify_on_exit!()
    :ok
  end

  describe "import_regions/1" do
    test "creates new locations from API data" do
      locations = [
        pinball_map_location(%{"id" => 100, "name" => "Arcade A"}),
        pinball_map_location(%{"id" => 200, "name" => "Arcade B"})
      ]

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => locations})
      end)

      assert {:ok, summary} = Import.import_regions(regions: ["portland"])

      assert summary.created == 2
      assert summary.updated == 0
      assert summary.errors == 0
      assert summary.regions_processed == 1
    end

    test "updates existing locations on subsequent imports" do
      # First import
      locations = [pinball_map_location(%{"id" => 100, "name" => "Original Name"})]

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => locations})
      end)

      assert {:ok, _} = Import.import_regions(regions: ["portland"])

      # Second import with updated name
      updated_locations = [pinball_map_location(%{"id" => 100, "name" => "Updated Name"})]

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => updated_locations})
      end)

      assert {:ok, summary} = Import.import_regions(regions: ["portland"])

      assert summary.created == 0
      assert summary.updated == 1
      assert summary.errors == 0

      scope = Scope.for_user(nil)
      [location] = Locations.list_locations(scope)
      assert location.name == "Updated Name"
      assert location.pinball_map_id == 100
    end

    test "is idempotent - re-importing same data produces updates" do
      locations = [pinball_map_location()]

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => locations})
      end)

      assert {:ok, first} = Import.import_regions(regions: ["portland"])
      assert first.created == 1

      assert {:ok, second} = Import.import_regions(regions: ["portland"])
      assert second.created == 0
      assert second.updated == 1
    end

    test "processes multiple regions" do
      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{
          "locations" => [pinball_map_location(%{"id" => System.unique_integer([:positive])})]
        })
      end)

      assert {:ok, summary} = Import.import_regions(regions: ["portland", "eugene"])

      assert summary.regions_processed == 2
      assert summary.created == 2
    end

    test "continues on region fetch errors" do
      call_count = :counters.new(1, [:atomics])

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        :counters.add(call_count, 1, 1)
        count = :counters.get(call_count, 1)

        if count == 1 do
          Plug.Conn.send_resp(conn, 500, "error")
        else
          Req.Test.json(conn, %{
            "locations" => [pinball_map_location(%{"id" => 999})]
          })
        end
      end)

      assert {:ok, summary} = Import.import_regions(regions: ["bad-region", "portland"])

      assert summary.errors == 1
      assert summary.created == 1
      assert summary.regions_processed == 1
    end

    test "parses string coordinates into floats" do
      locations = [
        pinball_map_location(%{
          "id" => 300,
          "lat" => "45.5237",
          "lon" => "-122.6782"
        })
      ]

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => locations})
      end)

      assert {:ok, _} = Import.import_regions(regions: ["portland"])

      scope = Scope.for_user(nil)
      [location] = Locations.list_locations(scope)
      assert location.latitude == 45.5237
      assert location.longitude == -122.6782
    end

    test "maps API fields to location schema fields" do
      locations = [
        pinball_map_location(%{
          "id" => 400,
          "name" => "Test Arcade",
          "street" => "123 Main St",
          "city" => "Portland",
          "state" => "OR",
          "zip" => "97209",
          "country" => "US"
        })
      ]

      Req.Test.stub(OP.PinballMap.Client, fn conn ->
        Req.Test.json(conn, %{"locations" => locations})
      end)

      assert {:ok, _} = Import.import_regions(regions: ["portland"])

      scope = Scope.for_user(nil)
      [location] = Locations.list_locations(scope)
      assert location.pinball_map_id == 400
      assert location.name == "Test Arcade"
      assert location.address == "123 Main St"
      assert location.city == "Portland"
      assert location.state == "OR"
      assert location.postal_code == "97209"
      assert location.country == "US"
    end
  end
end
