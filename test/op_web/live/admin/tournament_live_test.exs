defmodule OPWeb.Admin.TournamentLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures
  import OP.MatchplayFixtures
  import OP.TournamentsFixtures
  import OP.PlayersFixtures

  describe "Index - Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/tournaments")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects regular users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/admin/tournaments")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be a system admin to access this page."} = flash
    end

    test "allows system_admin users to access", %{conn: conn} do
      user = admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments")
      assert html =~ "Tournaments"
    end

    test "disallows td users to access", %{conn: conn} do
      # Note: 1/22/26: thinking TDs should have a separate
      # submission page with potentially different UX than
      # the system admin.  If we want to mirror it, we can
      # do that, too.
      user = td_user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, _lv} = live(conn, ~p"/admin/tournaments")
    end
  end

  describe "Index" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "lists all tournaments", %{conn: conn} do
      tournament = tournament_fixture(%{name: "Test Tournament"})

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments")

      assert html =~ "Tournaments"
      assert html =~ tournament.name
    end

    test "shows empty state when no tournaments", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments")

      assert html =~ "No tournaments found"
    end

    test "navigates to new tournament form", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments")

      assert lv |> element("a", "New Tournament") |> render_click() =~
               "New Tournament"
    end
  end

  describe "Create Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "creates a new tournament with valid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "New Test Tournament",
          "start_at" => start_at
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      html = render(lv)
      assert html =~ "Tournament created successfully"
      assert html =~ "New Test Tournament"
    end

    test "creates a tournament with finals_format", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "Finals Format Tournament",
          "start_at" => start_at,
          "finals_format" => "single_elimination"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      html = render(lv)
      assert html =~ "Tournament created successfully"
      assert html =~ "Finals Format Tournament"
    end

    test "creates a tournament with status", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "Sanctioned Tournament",
          "start_at" => start_at,
          "status" => "sanctioned"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      html = render(lv)
      assert html =~ "Tournament created successfully"
      assert html =~ "Sanctioned Tournament"
    end

    test "defaults status to draft", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/new")

      assert html =~ "Draft"
    end

    test "shows validation errors with invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      result =
        lv
        |> form("#tournament-form", %{
          "tournament" => %{
            "name" => ""
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "Update Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      tournament = tournament_fixture(%{name: "Original Name"})
      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "updates tournament with valid data", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "Updated Name"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      html = render(lv)
      assert html =~ "Tournament updated successfully"
      assert html =~ "Updated Name"
    end

    test "updates tournament finals_format", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "finals_format" => "double_elimination"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      html = render(lv)
      assert html =~ "Tournament updated successfully"
    end

    test "updates tournament status", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "status" => "pending_review"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      html = render(lv)
      assert html =~ "Tournament updated successfully"
    end

    test "shows validation errors with invalid data", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      result =
        lv
        |> form("#tournament-form", %{
          "tournament" => %{
            "name" => ""
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "Per-page selector" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders with default value of 25", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments")

      assert html =~ "Per page:"
      assert html =~ ~s(value="25" selected)
    end

    test "changing per_page updates URL and limits results", %{conn: conn} do
      for i <- 1..15, do: tournament_fixture(%{name: "Tournament #{i}"})

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments")

      lv
      |> element("form[phx-change=change_per_page]")
      |> render_change(%{"per_page" => "10"})

      path = assert_patch(lv)
      assert path =~ "per_page=10"

      html = render(lv)
      assert html =~ "of 15 tournaments"
      assert html =~ "1 to 10"
    end

    test "per_page persists with search", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments?per_page=10")

      lv
      |> form("#tournament-filters", %{"filters" => %{"search" => "test"}})
      |> render_change()

      path = assert_patch(lv)
      assert path =~ "per_page=10"
      assert path =~ "search=test"
    end

    test "per_page persists across pagination", %{conn: conn} do
      for i <- 1..15, do: tournament_fixture(%{name: "Tournament #{i}"})

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments?per_page=10")

      assert html =~ ~r/page=2[^"]*per_page=10|per_page=10[^"]*page=2/
    end
  end

  describe "Delete Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      tournament = tournament_fixture(%{name: "Tournament to Delete"})
      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "deletes tournament from list", %{conn: conn, tournament: tournament} do
      {:ok, lv, html} = live(conn, ~p"/admin/tournaments")

      assert html =~ tournament.name

      lv
      |> element("button[phx-click=delete]")
      |> render_click()

      refute render(lv) =~ tournament.name
    end
  end

  describe "Re-sync from Matchplay" do
    setup do
      Req.Test.set_req_test_to_shared(OP.Matchplay.Client)
      :ok
    end

    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

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

    test "shows button for matchplay tournaments", %{conn: conn} do
      tournament =
        tournament_fixture(nil, %{
          name: "Matchplay Tournament",
          external_id: "matchplay:12345"
        })

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}")
      assert html =~ "Re-sync from Matchplay"
    end

    test "does not show button for non-matchplay tournaments", %{conn: conn} do
      tournament = tournament_fixture(nil, %{name: "Regular Tournament"})

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}")
      refute html =~ "Re-sync from Matchplay"
    end

    test "successful resync shows flash message", %{conn: conn} do
      player = player_with_external_id_fixture(nil, "matchplay:1001", %{name: "Alice Smith"})

      tournament =
        tournament_fixture(nil, %{
          name: "Matchplay Tournament",
          external_id: "matchplay:12345"
        })

      _standing = standing_fixture(tournament, player, %{position: 1})

      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "players" => [tournament_player(101, "Alice Smith", 1001)]
        }),
        standings_response([{101, 1}])
      )

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      lv
      |> element("button", "Re-sync from Matchplay")
      |> render_click()

      :timer.sleep(200)
      html = render(lv)
      assert html =~ "Re-synced"
      assert html =~ "standings"
    end

    test "failed resync shows error flash", %{conn: conn} do
      tournament =
        tournament_fixture(nil, %{
          name: "Matchplay Tournament",
          external_id: "matchplay:99999"
        })

      stub_matchplay_error(404)

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      lv
      |> element("button", "Re-sync from Matchplay")
      |> render_click()

      :timer.sleep(200)
      html = render(lv)
      assert html =~ "Re-sync failed"
    end
  end

  describe "Organizer Search" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "organizer search field is visible on new tournament form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/new")

      assert html =~ "Organizer"
      assert html =~ "Search by email..."
    end

    test "pre-populates organizer on edit when one exists", %{conn: conn} do
      organizer = user_fixture(%{email: "organizer@example.com"})

      tournament =
        tournament_fixture(nil, %{name: "Organized Tournament", organizer_id: organizer.id})

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      html = render(lv)
      assert html =~ "organizer@example.com"
    end

    test "searching by email shows matching results", %{conn: conn} do
      _target_user = user_fixture(%{email: "findme@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      lv
      |> element("#organizer-search-input")
      |> render_keyup(%{"value" => "findme"})

      html = render(lv)
      assert html =~ "findme@example.com"
    end

    test "selecting an organizer displays email with clear button", %{conn: conn} do
      target_user = user_fixture(%{email: "selected@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      lv
      |> element("#organizer-search-input")
      |> render_keyup(%{"value" => "selected"})

      lv
      |> element(~s(button[phx-click="select_organizer"][phx-value-user-id="#{target_user.id}"]))
      |> render_click()

      html = render(lv)
      assert html =~ "selected@example.com"
      assert html =~ "hero-x-mark"
    end

    test "clearing selected organizer shows search input again", %{conn: conn} do
      target_user = user_fixture(%{email: "clearme@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      lv
      |> element("#organizer-search-input")
      |> render_keyup(%{"value" => "clearme"})

      lv
      |> element(~s(button[phx-click="select_organizer"][phx-value-user-id="#{target_user.id}"]))
      |> render_click()

      lv
      |> element(~s(button[phx-click="clear_organizer"]))
      |> render_click()

      html = render(lv)
      assert html =~ "Search by email..."
      refute html =~ "clearme@example.com"
    end
  end

  describe "Matchplay URL fields" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "fields render on new tournament form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/new")

      assert html =~ "Qualifying Matchplay URL"
      assert html =~ "Finals Matchplay URL"
      assert html =~ "Enter a Matchplay tournament URL or numeric ID"
    end

    test "fields render on edit tournament form", %{conn: conn} do
      tournament = tournament_fixture(%{name: "Test Tournament"})
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      assert html =~ "Qualifying Matchplay URL"
      assert html =~ "Finals Matchplay URL"
    end

    test "existing external_id displays as full URL in edit form", %{conn: conn} do
      tournament =
        tournament_fixture(nil, %{
          name: "Matchplay Tournament",
          external_id: "matchplay:12345"
        })

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      assert html =~ "https://app.matchplay.events/tournaments/12345"
    end

    test "existing finals_external_id displays as full URL in edit form", %{conn: conn} do
      tournament =
        tournament_fixture(nil, %{
          name: "Finals Tournament",
          finals_external_id: "matchplay:67890"
        })

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      assert html =~ "https://app.matchplay.events/tournaments/67890"
    end

    test "saving a URL sets external_id correctly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "URL Tournament",
          "start_at" => start_at,
          "qualifying_matchplay_url" => "https://app.matchplay.events/tournaments/11111"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      tournament =
        OP.Tournaments.list_tournaments(nil) |> Enum.find(&(&1.name == "URL Tournament"))

      assert tournament.external_id == "matchplay:11111"
      assert tournament.external_url == "https://app.matchplay.events/tournaments/11111"
    end

    test "saving a numeric ID sets external_id correctly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "Numeric ID Tournament",
          "start_at" => start_at,
          "qualifying_matchplay_url" => "22222"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      tournament =
        OP.Tournaments.list_tournaments(nil) |> Enum.find(&(&1.name == "Numeric ID Tournament"))

      assert tournament.external_id == "matchplay:22222"
    end

    test "saving finals URL sets finals_external_id correctly", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "Finals URL Tournament",
          "start_at" => start_at,
          "finals_matchplay_url" => "https://app.matchplay.events/tournaments/33333"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      tournament =
        OP.Tournaments.list_tournaments(nil) |> Enum.find(&(&1.name == "Finals URL Tournament"))

      assert tournament.finals_external_id == "matchplay:33333"
    end

    test "clearing URL clears external_id", %{conn: conn} do
      tournament =
        tournament_fixture(nil, %{
          name: "Clear Test",
          external_id: "matchplay:44444",
          external_url: "https://app.matchplay.events/tournaments/44444"
        })

      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "qualifying_matchplay_url" => ""
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/admin/tournaments")

      updated = OP.Tournaments.get_tournament!(nil, tournament.id)
      assert updated.external_id == nil
      assert updated.external_url == nil
    end
  end

  describe "Show Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      tournament = tournament_fixture(%{name: "Show Tournament", description: "Test description"})
      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "displays tournament details", %{conn: conn, tournament: tournament} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      assert html =~ tournament.name
      assert html =~ "Tournament details"
    end

    test "navigates to edit from show page", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      assert lv |> element("a", "Edit Tournament") |> render_click() =~
               "Edit Tournament"
    end

    test "redirects non-admin users", %{tournament: tournament} do
      user = user_fixture()
      non_admin_conn = log_in_user(build_conn(), user)

      assert {:error, redirect} = live(non_admin_conn, ~p"/admin/tournaments/#{tournament}")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/"
    end

    test "displays point breakdown with standings", %{conn: conn} do
      player = player_fixture()
      tournament = tournament_fixture(nil, %{meaningful_games: 13.5})
      standing_fixture(tournament, player, %{position: 1})

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      assert html =~ "Point Breakdown"
      assert html =~ "Linear"
      assert html =~ "Dynamic"
      assert html =~ "Weight"
      assert html =~ "54%"
    end

    test "does not display point breakdown without meaningful_games", %{
      conn: conn,
      tournament: tournament
    } do
      player = player_fixture()
      standing_fixture(tournament, player, %{position: 1})

      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      refute html =~ "Point Breakdown"
    end
  end
end
