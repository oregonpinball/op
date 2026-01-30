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
        |> element(~s{button[data-confirm]})
        |> render_click()

      assert html =~ "Player scrubbed successfully"
      assert html =~ "Deleted Player"
      refute html =~ "Player to Scrub"
      refute html =~ "ext-123"
    end
  end

  describe "Index - search" do
    setup :register_and_log_in_system_admin

    test "filters players by search term", %{conn: conn} do
      player_fixture(nil, %{name: "John Doe"})
      player_fixture(nil, %{name: "Jane Smith"})

      {:ok, lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "John Doe"
      assert html =~ "Jane Smith"

      html =
        lv
        |> form("#player-filters", %{"search" => "john"})
        |> render_change()

      assert html =~ "John Doe"
      refute html =~ "Jane Smith"
    end

    test "shows no results message when search has no matches", %{conn: conn} do
      player_fixture(nil, %{name: "Test Player"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players")

      html =
        lv
        |> form("#player-filters", %{"search" => "nonexistent"})
        |> render_change()

      assert html =~ "No players match your search criteria"
    end

    test "preserves search in URL", %{conn: conn} do
      player_fixture(nil, %{name: "John Doe"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players")

      lv
      |> form("#player-filters", %{"search" => "john"})
      |> render_change()

      assert_patch(lv, ~p"/admin/players?page=1&search=john")
    end

    test "loads with search from URL params", %{conn: conn} do
      player_fixture(nil, %{name: "John Doe"})
      player_fixture(nil, %{name: "Jane Smith"})

      {:ok, _lv, html} = live(conn, ~p"/admin/players?search=john")

      assert html =~ "John Doe"
      refute html =~ "Jane Smith"
    end
  end

  describe "Index - filters" do
    setup :register_and_log_in_system_admin

    test "filters by linked status - linked", %{conn: conn} do
      user = user_fixture()
      linked_player = player_fixture(nil, %{name: "Linked Player"})
      {:ok, _} = Players.link_user(nil, linked_player, user.id)
      _unlinked_player = player_fixture(nil, %{name: "Unlinked Player"})

      {:ok, lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "Linked Player"
      assert html =~ "Unlinked Player"

      html =
        lv
        |> form("#player-filters", %{"linked" => "linked"})
        |> render_change()

      assert html =~ "Linked Player"
      refute html =~ "Unlinked Player"
    end

    test "filters by linked status - unlinked", %{conn: conn} do
      user = user_fixture()
      linked_player = player_fixture(nil, %{name: "Linked Player"})
      {:ok, _} = Players.link_user(nil, linked_player, user.id)
      _unlinked_player = player_fixture(nil, %{name: "Unlinked Player"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players")

      html =
        lv
        |> form("#player-filters", %{"linked" => "unlinked"})
        |> render_change()

      refute html =~ "Linked Player"
      assert html =~ "Unlinked Player"
    end

    test "clears filter when selecting all", %{conn: conn} do
      user = user_fixture()
      linked_player = player_fixture(nil, %{name: "Linked Player"})
      {:ok, _} = Players.link_user(nil, linked_player, user.id)
      _unlinked_player = player_fixture(nil, %{name: "Unlinked Player"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players?linked=linked")

      html =
        lv
        |> form("#player-filters", %{"linked" => ""})
        |> render_change()

      assert html =~ "Linked Player"
      assert html =~ "Unlinked Player"
    end

    test "preserves filter in URL", %{conn: conn} do
      player_fixture(nil, %{name: "Test Player"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players")

      lv
      |> form("#player-filters", %{"linked" => "linked"})
      |> render_change()

      assert_patch(lv, ~p"/admin/players?linked=linked&page=1")
    end

    test "loads with filter from URL params", %{conn: conn} do
      user = user_fixture()
      linked_player = player_fixture(nil, %{name: "Linked Player"})
      {:ok, _} = Players.link_user(nil, linked_player, user.id)
      _unlinked_player = player_fixture(nil, %{name: "Unlinked Player"})

      {:ok, _lv, html} = live(conn, ~p"/admin/players?linked=unlinked")

      refute html =~ "Linked Player"
      assert html =~ "Unlinked Player"
    end

    test "combines search and filter", %{conn: conn} do
      user = user_fixture()
      linked_john = player_fixture(nil, %{name: "John Linked"})
      {:ok, _} = Players.link_user(nil, linked_john, user.id)
      _unlinked_john = player_fixture(nil, %{name: "John Unlinked"})
      linked_jane = player_fixture(nil, %{name: "Jane Linked"})
      {:ok, _} = Players.link_user(nil, linked_jane, user.id)

      {:ok, lv, _html} = live(conn, ~p"/admin/players")

      html =
        lv
        |> form("#player-filters", %{"search" => "john", "linked" => "linked"})
        |> render_change()

      assert html =~ "John Linked"
      refute html =~ "John Unlinked"
      refute html =~ "Jane Linked"
    end
  end

  describe "Index - pagination" do
    setup :register_and_log_in_system_admin

    test "shows pagination when more than one page", %{conn: conn} do
      for i <- 1..30 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "30 players total"
      # Should have pagination nav
      assert html =~ "aria-label=\"Pagination\""
      # Should show page 2 link
      assert html =~ "page=2"
    end

    test "does not show pagination when only one page", %{conn: conn} do
      player_fixture(nil, %{name: "Only Player"})

      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      refute html =~ "aria-label=\"Pagination\""
    end

    test "navigates to next page", %{conn: conn} do
      for i <- 1..30 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      # Page 1 shows first 25 players (alphabetically)
      assert html =~ "Player 01"
      assert html =~ "Player 25"
      refute html =~ "Player 26"

      # Navigate to page 2
      {:ok, _lv, html} = live(conn, ~p"/admin/players?page=2")

      refute html =~ "Player 01"
      assert html =~ "Player 26"
      assert html =~ "Player 30"
    end

    test "preserves filters when paginating", %{conn: conn} do
      user = user_fixture()

      for i <- 1..30 do
        player = player_fixture(nil, %{name: "Linked #{String.pad_leading("#{i}", 2, "0")}"})
        {:ok, _} = Players.link_user(nil, player, user.id)
      end

      for i <- 1..5 do
        player_fixture(nil, %{name: "Unlinked #{String.pad_leading("#{i}", 2, "0")}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/players?linked=linked&page=2")

      # Should only show linked players on page 2
      assert html =~ "Linked 26"
      refute html =~ "Unlinked"
    end

    test "resets to page 1 when filter changes", %{conn: conn} do
      for i <- 1..30 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      {:ok, lv, _html} = live(conn, ~p"/admin/players?page=2")

      lv
      |> form("#player-filters", %{"search" => "player"})
      |> render_change()

      # Filter change should reset to page 1
      assert_patch(lv, ~p"/admin/players?page=1&search=player")
    end

    test "loads correct page from URL params", %{conn: conn} do
      for i <- 1..30 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/players?page=2")

      refute html =~ "Player 01"
      assert html =~ "Player 26"
    end

    test "handles invalid page number gracefully", %{conn: conn} do
      player_fixture(nil, %{name: "Test Player"})

      {:ok, _lv, html} = live(conn, ~p"/admin/players?page=invalid")

      assert html =~ "Test Player"
    end

    test "handles page number 0 gracefully", %{conn: conn} do
      player_fixture(nil, %{name: "Test Player"})

      {:ok, _lv, html} = live(conn, ~p"/admin/players?page=0")

      assert html =~ "Test Player"
    end
  end

  describe "Index - total count" do
    setup :register_and_log_in_system_admin

    test "shows total count in subtitle", %{conn: conn} do
      for i <- 1..5 do
        player_fixture(nil, %{name: "Player #{i}"})
      end

      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "5 players total"
    end

    test "shows filtered count", %{conn: conn} do
      player_fixture(nil, %{name: "John Doe"})
      player_fixture(nil, %{name: "John Smith"})
      player_fixture(nil, %{name: "Jane Doe"})

      {:ok, _lv, html} = live(conn, ~p"/admin/players?search=john")

      assert html =~ "2 players total"
    end

    test "shows no players yet when empty", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/players")

      assert html =~ "No players yet"
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
        |> form("#user-search-form", search: %{user_search: "searchable"})
        |> render_change()

      assert html =~ "searchable@example.com"
    end

    test "can link a user to player", %{conn: conn} do
      player = player_fixture(nil, %{name: "Player"})
      user = user_fixture(%{email: "linkme@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/players/#{player.slug}/edit")

      # Search for user
      lv
      |> form("#user-search-form", search: %{user_search: "linkme"})
      |> render_change()

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
        |> form("#user-search-form", search: %{user_search: "nonexistent"})
        |> render_change()

      assert html =~ "No users found matching"
    end
  end
end
