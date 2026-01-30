defmodule OP.LocationsTest do
  use OP.DataCase

  alias OP.Locations

  import OP.LocationsFixtures

  describe "search_locations/2" do
    test "finds locations by partial name match" do
      location_fixture(%{name: "Fun Arcade"})
      location_fixture(%{name: "Cool Bar"})

      results = Locations.search_locations(nil, "arcade")
      assert length(results) == 1
      assert hd(results).name == "Fun Arcade"
    end

    test "search is case insensitive" do
      location_fixture(%{name: "Fun Arcade"})

      assert length(Locations.search_locations(nil, "FUN")) == 1
      assert length(Locations.search_locations(nil, "fun")) == 1
    end

    test "returns empty list for no matches" do
      location_fixture(%{name: "Fun Arcade"})

      assert Locations.search_locations(nil, "xyz") == []
    end

    test "returns empty list for empty query" do
      location_fixture(%{name: "Fun Arcade"})

      assert Locations.search_locations(nil, "") == []
    end
  end
end
