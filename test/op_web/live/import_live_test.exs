defmodule OPWeb.ImportLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures
  import OP.LeaguesFixtures
  import OP.LocationsFixtures
  import OP.MatchplayFixtures
  import OP.PlayersFixtures

  setup do
    # Set up Req.Test in shared mode so stubs work across async processes
    Req.Test.set_req_test_to_shared(OP.Matchplay.Client)
    :ok
  end

  # Helper to create a stub that handles path matching correctly
  defp stub_matchplay_api(tournament_data, standings_data) do
    Req.Test.stub(OP.Matchplay.Client, fn plug_conn ->
      path = plug_conn.request_path

      cond do
        String.ends_with?(path, "/standings") ->
          Req.Test.json(plug_conn, standings_data)

        String.contains?(path, "/tournaments/") ->
          Req.Test.json(plug_conn, %{"data" => tournament_data})

        true ->
          Req.Test.json(plug_conn, %{})
      end
    end)
  end

  defp stub_matchplay_error(status_code) do
    Req.Test.stub(OP.Matchplay.Client, fn plug_conn ->
      Plug.Conn.send_resp(plug_conn, status_code, "")
    end)
  end

  describe "access control" do
    test "redirects to login when not authenticated", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/import")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "renders import page when authenticated", %{conn: conn} do
      {:ok, _view, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/import")

      assert html =~ "Import from Matchplay"
      assert html =~ "Matchplay Tournament ID"
    end
  end

  describe "enter_id step" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders the tournament ID form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/import")

      assert html =~ "Matchplay Tournament ID"
      assert has_element?(view, "#import-form")
      assert has_element?(view, "input[name='matchplay_id']")
    end

    test "shows fetch button", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/import")

      assert has_element?(view, "button[type='submit']")
    end

    test "shows helper text with example URL", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/import")

      assert html =~ "https://app.matchplay.events/tournaments/"
    end
  end

  describe "fetch_preview with mocked API" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = OP.Accounts.Scope.for_user(user)
      %{conn: log_in_user(conn, user), user: user, scope: scope}
    end

    test "transitions to match_players step on successful fetch", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{"tournamentId" => 12345}),
        standings_response()
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      # Wait a bit for async to complete
      :timer.sleep(100)

      html = render(view)
      assert html =~ "Test Tournament"
      assert html =~ "Match Players"
    end

    test "extracts tournament ID from full URL", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{"tournamentId" => 98765}),
        standings_response()
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{
        matchplay_id: "https://app.matchplay.events/tournaments/98765/standings"
      })
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "Test Tournament"
    end

    test "shows error step on API error", %{conn: conn} do
      stub_matchplay_error(404)

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "99999"})
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "not found"
    end
  end

  describe "match_players step" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = OP.Accounts.Scope.for_user(user)

      # Create some existing players
      player1 = player_fixture(scope, %{name: "Alice Smith"})
      player2 = player_fixture(scope, %{name: "Bob Jones"})

      %{
        conn: log_in_user(conn, user),
        user: user,
        scope: scope,
        players: [player1, player2]
      }
    end

    test "displays player rows with positions", %{conn: conn} do
      stub_matchplay_api(tournament_response(), standings_response())

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)
      html = render(view)

      # Check player names from standings are displayed
      assert html =~ "Alice Smith"
      assert html =~ "Bob Jones"
      assert html =~ "Charlie Brown"
    end

    test "shows auto-matched badge for players with matching external_id", %{
      conn: conn,
      scope: scope
    } do
      # Create player with matchplay external_id (using claimedBy userId)
      _auto_player =
        player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Auto User"})

      # Tournament includes player with playerId=201, claimedBy=1001
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(201, "Auto User", 1001)]
        }),
        standings_response([{201, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "Auto-matched"
    end

    test "shows suggested badge for players with exact name match", %{conn: conn, scope: scope} do
      # Create player with exact matching name
      _suggested_player = player_fixture(scope, %{name: "Match Me"})

      # Tournament player has no claimedBy, so external_id will be playerId
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(202, "Match Me", nil)]
        }),
        standings_response([{202, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "Suggested"
    end

    test "continue button is disabled when unmatched players exist", %{conn: conn} do
      # Player with no claimedBy and no name match in DB
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(999, "Unknown Player", nil)]
        }),
        standings_response([{999, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)
      # The continue button should be disabled
      assert has_element?(view, "button[disabled]", "Continue")
    end
  end

  describe "player interaction" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = OP.Accounts.Scope.for_user(user)

      searchable_player = player_fixture(scope, %{name: "Searchable Player"})

      %{
        conn: log_in_user(conn, user),
        scope: scope,
        searchable_player: searchable_player
      }
    end

    test "create_new_player sets match_type to create_new", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(999, "Unknown Player", nil)]
        }),
        standings_response([{999, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      # Click create new button
      view
      |> element("button", "Create New")
      |> render_click()

      html = render(view)
      assert html =~ "Create New"
      assert html =~ "Will create: Unknown Player"
    end

    test "search_player returns matching players", %{conn: conn, searchable_player: player} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(999, "Unknown", nil)]
        }),
        standings_response([{999, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      # Search for player
      view
      |> form("form[phx-change='search_player']", %{query: "Searchable", index: "0"})
      |> render_change()

      html = render(view)
      assert html =~ player.name
    end
  end

  describe "tournament_details step" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = OP.Accounts.Scope.for_user(user)

      auto_player =
        player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Auto Player"})

      location = location_fixture(%{name: "Test Location"})
      league = league_fixture()
      season = season_fixture(league)

      %{
        conn: log_in_user(conn, user),
        scope: scope,
        auto_player: auto_player,
        location: location,
        league: league,
        season: season
      }
    end

    test "displays import summary with counts", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)]
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      # All players are auto-matched, so continue should be enabled
      view
      |> element("button", "Continue")
      |> render_click()

      html = render(view)
      assert html =~ "Import Summary"
      assert html =~ "Total Players"
      assert html =~ "Auto-matched"
    end

    test "displays tournament details form", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)]
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      html = render(view)
      assert html =~ "Tournament Details"
      assert html =~ "Tournament Name"
      assert html =~ "Description"
      assert html =~ "Start Date"
      assert html =~ "Location"
      assert html =~ "League"
      assert html =~ "Season"
    end

    test "displays location dropdown with options", %{conn: conn, location: location} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)]
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      html = render(view)
      assert html =~ location.name
    end

    test "displays Matchplay venue info when available", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)],
          "location" => %{
            "locationId" => 9999,
            "name" => "Matchplay Venue",
            "address" => "456 Arcade St"
          }
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      html = render(view)
      assert html =~ "Matchplay venue"
      assert html =~ "Matchplay Venue"
      assert html =~ "456 Arcade St"
    end

    test "auto-matches location by external_id", %{conn: conn, scope: scope} do
      # Create location with matchplay external_id
      matched_location =
        location_with_external_id_fixture("matchplay:6201", %{
          scope: scope,
          name: "Auto-matched Location"
        })

      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)],
          "location" => %{
            "locationId" => 6201,
            "name" => "Different Name",
            "address" => "123 Test St"
          }
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      html = render(view)
      assert html =~ "Auto-matched to local location"
      # The dropdown should have the matched location selected
      assert html =~ matched_location.name
    end

    test "filters seasons when league is selected", %{conn: conn, league: league, season: season} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)]
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      # Select the league
      view
      |> form("#tournament-details-form", %{league_id: to_string(league.id)})
      |> render_change()

      html = render(view)
      # Season dropdown should now show the season
      assert html =~ season.name
    end

    test "import button disabled until required fields selected", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)]
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      # Import button should be disabled (no location or season selected)
      assert has_element?(view, "button[disabled]", "Import Tournament")
    end

    test "back_to_match returns to match_players step", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(301, "Auto Player", 1001)]
        }),
        standings_response([{301, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      # Click back
      view
      |> element("button", "Back")
      |> render_click()

      html = render(view)
      assert html =~ "Match Players"
    end
  end

  describe "execute_import" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = OP.Accounts.Scope.for_user(user)

      auto_player =
        player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Auto Player"})

      location = location_fixture(%{name: "Import Test Location"})
      league = league_fixture()
      season = season_fixture(league)

      %{
        conn: log_in_user(conn, user),
        scope: scope,
        auto_player: auto_player,
        location: location,
        league: league,
        season: season
      }
    end

    test "shows success step on successful import", %{
      conn: conn,
      location: location,
      league: league,
      season: season
    } do
      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "players" => [tournament_player(401, "Auto Player", 1001)]
        }),
        standings_response([{401, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      # Fill in required fields
      view
      |> form("#tournament-details-form", %{
        location_id: to_string(location.id),
        league_id: to_string(league.id)
      })
      |> render_change()

      view
      |> form("#tournament-details-form", %{season_id: to_string(season.id)})
      |> render_change()

      # Submit the form
      view
      |> form("#tournament-details-form")
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "Import Successful"
      assert html =~ "Test Tournament"
    end

    test "displays import results", %{
      conn: conn,
      location: location,
      league: league,
      season: season
    } do
      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 55555,
          "players" => [tournament_player(501, "Auto Player", 1001)]
        }),
        standings_response([{501, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "55555"})
      |> render_submit()

      :timer.sleep(100)

      view
      |> element("button", "Continue")
      |> render_click()

      # Fill in required fields
      view
      |> form("#tournament-details-form", %{
        location_id: to_string(location.id),
        league_id: to_string(league.id)
      })
      |> render_change()

      view
      |> form("#tournament-details-form", %{season_id: to_string(season.id)})
      |> render_change()

      # Submit the form
      view
      |> form("#tournament-details-form")
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "Players Created"
      assert html =~ "Players Updated"
      assert html =~ "Standings"
    end
  end

  describe "navigation" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "back_to_id returns to enter_id step", %{conn: conn} do
      stub_matchplay_api(tournament_response(), standings_response())

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      # Should be on match_players step
      html = render(view)
      assert html =~ "Match Players"

      # Click back
      view
      |> element("button", "Back")
      |> render_click()

      html = render(view)
      assert html =~ "Matchplay Tournament ID"
    end

    test "reset clears state and returns to enter_id", %{conn: conn} do
      stub_matchplay_api(
        tournament_response(%{
          "players" => [tournament_player(601, "Player", nil)]
        }),
        standings_response([{601, 1}])
      )

      {:ok, view, _html} = live(conn, ~p"/import")

      # Go to match_players step
      view
      |> form("#import-form", %{matchplay_id: "12345"})
      |> render_submit()

      :timer.sleep(100)

      # Mark player for creation
      view
      |> element("button", "Create New")
      |> render_click()

      # Continue to confirm
      view
      |> element("button", "Continue")
      |> render_click()

      # Click back and then back again to enter_id
      view
      |> element("button", "Back")
      |> render_click()

      view
      |> element("button", "Back")
      |> render_click()

      html = render(view)
      assert html =~ "Matchplay Tournament ID"
    end
  end

  describe "error handling" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user)}
    end

    test "displays NotFoundError with tournament ID", %{conn: conn} do
      stub_matchplay_error(404)

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "99999"})
      |> render_submit()

      :timer.sleep(100)
      html = render(view)
      assert html =~ "not found"
      assert html =~ "Import Failed"
    end

    test "Try Again button resets state", %{conn: conn} do
      stub_matchplay_error(404)

      {:ok, view, _html} = live(conn, ~p"/import")

      view
      |> form("#import-form", %{matchplay_id: "99999"})
      |> render_submit()

      :timer.sleep(100)

      # Should be on error step
      html = render(view)
      assert html =~ "Import Failed"

      # Click Try Again
      view
      |> element("button", "Try Again")
      |> render_click()

      html = render(view)
      assert html =~ "Matchplay Tournament ID"
    end
  end
end
