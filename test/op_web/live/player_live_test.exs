defmodule OPWeb.PlayerLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.PlayersFixtures
  import OP.AccountsFixtures

  alias OP.Players

  describe "Index" do
    setup :register_and_log_in_system_admin

    test "lists all players", %{conn: conn} do
      player = player_fixture(nil, %{name: "Test Player"})
      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "Manage Players"
      assert html =~ player.name
    end

    test "shows empty state when no players", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "No players found"
    end

    test "shows linked user email when player has user", %{conn: conn} do
      player = player_fixture(nil, %{name: "Linked Player"})
      user = user_fixture(%{email: "linked@example.com"})
      {:ok, _} = Players.link_user(nil, player, user.id)

      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "linked@example.com"
    end

    test "scrubs player (anonymizes data)", %{conn: conn} do
      _player = player_fixture(nil, %{name: "Player to Scrub", external_id: "ext-123"})
      {:ok, lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "Player to Scrub"
      assert html =~ "ext-123"

      html =
        lv
        |> element("button", "Scrub")
        |> render_click()

      assert html =~ "Player scrubbed successfully"
      assert html =~ "Deleted Player"
      refute html =~ "Player to Scrub"
      refute html =~ "ext-123"
    end
  end

  describe "Index - unauthorized access" do
    test "redirects if not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/players")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert flash["error"] =~ "system admin"
    end

    setup :register_and_log_in_user

    test "redirects if not system admin", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/players")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert flash["error"] =~ "system admin"
    end
  end

  describe "Form - new" do
    setup :register_and_log_in_system_admin

    test "renders new player form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/players/new")

      assert html =~ "New Player"
      assert html =~ "Name"
    end

    test "creates new player", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/players/new")

      {:ok, _lv, html} =
        lv
        |> form("#player-form", player: %{name: "New Test Player"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/players")

      assert html =~ "Player created successfully"
      assert html =~ "New Test Player"
    end

    test "validates form on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/players/new")

      html =
        lv
        |> form("#player-form", player: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "does not show user linking section in new mode", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/players/new")

      refute html =~ "Linked User Account"
    end
  end

  describe "Form - edit" do
    setup :register_and_log_in_system_admin

    test "renders edit player form", %{conn: conn} do
      player = player_fixture(nil, %{name: "Edit Me"})
      {:ok, _lv, html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      assert html =~ "Edit Player"
      assert html =~ "Edit Me"
    end

    test "updates player", %{conn: conn} do
      player = player_fixture(nil, %{name: "Original Name"})
      {:ok, lv, _html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      {:ok, _lv, html} =
        lv
        |> form("#player-form", player: %{name: "Updated Name"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/players")

      assert html =~ "Player updated successfully"
      assert html =~ "Updated Name"
    end

    test "shows user linking section in edit mode", %{conn: conn} do
      player = player_fixture(nil, %{name: "Player"})
      {:ok, _lv, html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      assert html =~ "Linked User Account"
      assert html =~ "No user account linked"
    end
  end

  describe "Form - user linking" do
    setup :register_and_log_in_system_admin

    test "can search for users by email", %{conn: conn} do
      player = player_fixture(nil, %{name: "Player"})
      user_fixture(%{email: "searchable@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      html =
        lv
        |> element("#user-search")
        |> render_change(%{"user_search" => "searchable"})

      assert html =~ "searchable@example.com"
    end

    test "can link a user to player", %{conn: conn} do
      player = player_fixture(nil, %{name: "Player"})
      user = user_fixture(%{email: "linkme@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      # Search for user
      lv
      |> element("#user-search")
      |> render_change(%{"user_search" => "linkme"})

      # Link the user
      html =
        lv
        |> element("button", "Link")
        |> render_click()

      assert html =~ "User linked successfully"
      assert html =~ "linkme@example.com"
      assert html =~ "Currently linked"

      # Verify in database
      reloaded = Players.get_player_by_slug!(nil, player.slug)
      assert reloaded.user_id == user.id
    end

    test "can unlink a user from player", %{conn: conn} do
      user = user_fixture(%{email: "linked@example.com"})
      player = player_fixture(nil, %{name: "Player"})
      {:ok, _} = Players.link_user(nil, player, user.id)

      {:ok, lv, html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      assert html =~ "linked@example.com"
      assert html =~ "Currently linked"

      html =
        lv
        |> element("button", "Unlink")
        |> render_click()

      assert html =~ "User unlinked successfully"
      assert html =~ "No user account linked"

      # Verify in database
      reloaded = Players.get_player_by_slug!(nil, player.slug)
      assert reloaded.user_id == nil
    end

    test "shows no results message when user search has no matches", %{conn: conn} do
      player = player_fixture(nil, %{name: "Player"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      html =
        lv
        |> element("#user-search")
        |> render_change(%{"user_search" => "nonexistent"})

      assert html =~ "No users found matching"
    end
  end
end
