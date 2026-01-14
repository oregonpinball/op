defmodule OPWeb.LocationControllerTest do
  use OPWeb.ConnCase

  import OP.LocationsFixtures

  describe "GET /locations" do
    test "lists all locations", %{conn: conn} do
      location = location_fixture(%{name: "Test Arcade"})
      conn = get(conn, ~p"/locations")

      assert html_response(conn, 200) =~ "Locations"
      assert html_response(conn, 200) =~ location.name
    end

    test "shows empty state when no locations", %{conn: conn} do
      conn = get(conn, ~p"/locations")

      assert html_response(conn, 200) =~ "No locations found"
    end
  end

  describe "GET /locations/:slug" do
    test "shows location details", %{conn: conn} do
      location = location_fixture(%{name: "Ground Kontrol", city: "Portland", state: "OR"})
      conn = get(conn, ~p"/locations/#{location.slug}")

      assert html_response(conn, 200) =~ location.name
      assert html_response(conn, 200) =~ "Portland"
    end
  end
end
