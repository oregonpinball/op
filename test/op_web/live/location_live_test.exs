defmodule OPWeb.LocationLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.LocationsFixtures

  describe "Index" do
    setup :register_and_log_in_system_admin

    test "lists all locations", %{conn: conn} do
      location = location_fixture(%{name: "Test Arcade"})
      {:ok, _lv, html} = live(conn, ~p"/admin/locations")

      assert html =~ "Manage Locations"
      assert html =~ location.name
    end

    test "shows empty state when no locations", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/locations")

      assert html =~ "No locations found"
    end

    test "deletes location", %{conn: conn} do
      location = location_fixture(%{name: "Location to Delete"})
      {:ok, lv, html} = live(conn, ~p"/admin/locations")

      assert html =~ location.name

      html =
        lv
        |> element("button", "Delete")
        |> render_click()

      refute html =~ location.name
    end
  end

  describe "Index - unauthorized access" do
    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/locations")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert flash["error"] =~ "system admin"
    end

    setup :register_and_log_in_user

    test "redirects if not system admin", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/locations")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert flash["error"] =~ "system admin"
    end
  end

  describe "Form - new" do
    setup :register_and_log_in_system_admin

    test "renders new location form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/locations/new")

      assert html =~ "New Location"
      assert html =~ "Name"
    end

    test "creates new location", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/locations/new")

      {:ok, _lv, html} =
        lv
        |> form("#location-form", location: %{name: "New Test Location", city: "Seattle"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/locations")

      assert html =~ "Location created successfully"
      assert html =~ "New Test Location"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/locations/new")

      html =
        lv
        |> form("#location-form", location: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Form - edit" do
    setup :register_and_log_in_system_admin

    test "renders edit location form", %{conn: conn} do
      location = location_fixture(%{name: "Edit Me"})
      {:ok, _lv, html} = live(conn, ~p"/admin/locations/#{location.slug}/edit")

      assert html =~ "Edit Location"
      assert html =~ "Edit Me"
    end

    test "updates location", %{conn: conn} do
      location = location_fixture(%{name: "Original Name"})
      {:ok, lv, _html} = live(conn, ~p"/admin/locations/#{location.slug}/edit")

      {:ok, _lv, html} =
        lv
        |> form("#location-form", location: %{name: "Updated Name"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/locations")

      assert html =~ "Location updated successfully"
      assert html =~ "Updated Name"
    end
  end
end
