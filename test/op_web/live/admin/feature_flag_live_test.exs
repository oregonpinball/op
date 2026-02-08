defmodule OPWeb.Admin.FeatureFlagLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures

  describe "Index - Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/feature-flags")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects regular users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/admin/feature-flags")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be a system admin to access this page."} = flash
    end

    test "redirects td users to home page", %{conn: conn} do
      user = td_user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/admin/feature-flags")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be a system admin to access this page."} = flash
    end

    test "allows system_admin users to access", %{conn: conn} do
      user = admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/admin/feature-flags")
      assert html =~ "Feature Flags"
    end
  end

  describe "Index - Rendering" do
    setup :register_and_log_in_system_admin

    test "renders page with header", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/feature-flags")

      assert html =~ "Feature Flags"
      assert html =~ "environment variables"
    end

    test "renders all flag cards", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/feature-flags")

      assert has_element?(lv, "#flag-registration_enabled")
      assert has_element?(lv, "#flag-tournament_submission_enabled")
    end

    test "shows enabled badges when flags are on", %{conn: conn} do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true
      )

      {:ok, lv, _html} = live(conn, ~p"/admin/feature-flags")

      assert render(lv) =~ "Enabled"
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true
      )
    end

    test "shows disabled badges when flags are off", %{conn: conn} do
      Application.put_env(:op, :feature_flags,
        registration_enabled: false,
        tournament_submission_enabled: false
      )

      {:ok, lv, _html} = live(conn, ~p"/admin/feature-flags")

      assert render(lv) =~ "Disabled"
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true
      )
    end
  end
end
