defmodule OPWeb.AdminLive.DashboardTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Dashboard" do
    setup :register_and_log_in_system_admin

    test "renders admin dashboard", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Admin Dashboard"
    end

    test "shows locations link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Locations"
      assert html =~ ~p"/admin/locations"
    end

    test "shows feature flags link", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/dashboard")

      assert html =~ "Feature Flags"
      assert html =~ ~p"/admin/feature-flags"
    end

    test "navigates to locations", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/dashboard")

      {:ok, _lv, html} =
        lv
        |> element("a", "Locations")
        |> render_click()
        |> follow_redirect(conn, ~p"/admin/locations")

      assert html =~ "Manage Locations"
    end
  end

  describe "Dashboard - unauthorized access" do
    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/dashboard")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert flash["error"] =~ "system admin"
    end

    setup :register_and_log_in_user

    test "redirects if not system admin", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/dashboard")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert flash["error"] =~ "system admin"
    end
  end
end
