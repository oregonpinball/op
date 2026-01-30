defmodule OPWeb.My.TournamentLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures
  import OP.TournamentsFixtures
  import OP.PlayersFixtures

  alias OP.Accounts.Scope

  describe "Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/my/tournaments")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "allows authenticated users to access", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/my/tournaments")
      assert html =~ "My Tournaments"
    end
  end

  describe "Organized tab" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = Scope.for_user(user)
      %{conn: log_in_user(conn, user), user: user, scope: scope}
    end

    test "shows tournaments where user is organizer", %{conn: conn, user: user} do
      _tournament = tournament_fixture(nil, %{name: "My Organized", organizer_id: user.id})

      {:ok, _lv, html} = live(conn, ~p"/my/tournaments")

      assert html =~ "My Organized"
    end

    test "does not show tournaments organized by other users", %{conn: conn} do
      other_user = user_fixture()
      tournament_fixture(nil, %{name: "Other Organized", organizer_id: other_user.id})

      {:ok, _lv, html} = live(conn, ~p"/my/tournaments")

      refute html =~ "Other Organized"
    end

    test "shows empty state when user has no organized tournaments", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/my/tournaments")

      assert html =~ "No organized tournaments found"
    end

    test "search filters organized tournaments", %{conn: conn, user: user} do
      tournament_fixture(nil, %{name: "Alpha Tournament", organizer_id: user.id})
      tournament_fixture(nil, %{name: "Beta Tournament", organizer_id: user.id})

      {:ok, lv, _html} = live(conn, ~p"/my/tournaments")

      lv
      |> form("#organized-filters", %{"filters" => %{"search" => "Alpha"}})
      |> render_change()

      path = assert_patch(lv)
      assert path =~ "org_search=Alpha"
    end
  end

  describe "Played tab" do
    setup %{conn: conn} do
      user = user_fixture()
      scope = Scope.for_user(user)
      player = player_fixture(scope, %{name: "Test Player"})
      {:ok, player} = OP.Players.link_user(scope, player, user.id)
      %{conn: log_in_user(conn, user), user: user, scope: scope, player: player}
    end

    test "shows tournaments where user's player has standings", %{conn: conn, player: player} do
      tournament = tournament_fixture(nil, %{name: "Played Tournament"})
      standing_fixture(tournament, player, %{position: 3})

      {:ok, _lv, html} = live(conn, ~p"/my/tournaments?tab=played")

      assert html =~ "Played Tournament"
    end

    test "does not show tournaments where user has no standings", %{conn: conn} do
      other_player = player_fixture(nil, %{name: "Other Player"})
      tournament = tournament_fixture(nil, %{name: "Not Played"})
      standing_fixture(tournament, other_player, %{position: 1})

      {:ok, _lv, html} = live(conn, ~p"/my/tournaments?tab=played")

      refute html =~ "Not Played"
    end

    test "shows empty state when user has no played tournaments", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/my/tournaments?tab=played")

      assert html =~ "No played tournaments found"
    end

    test "search filters played tournaments", %{conn: conn, player: player} do
      t1 = tournament_fixture(nil, %{name: "Gamma Tournament"})
      t2 = tournament_fixture(nil, %{name: "Delta Tournament"})
      standing_fixture(t1, player, %{position: 1})
      standing_fixture(t2, player, %{position: 2})

      {:ok, lv, _html} = live(conn, ~p"/my/tournaments?tab=played")

      lv
      |> form("#played-filters", %{"filters" => %{"search" => "Gamma"}})
      |> render_change()

      path = assert_patch(lv)
      assert path =~ "played_search=Gamma"
    end
  end

  describe "User with no linked player" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "played tab shows empty when user has no linked player", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/my/tournaments?tab=played")

      assert html =~ "No played tournaments found"
    end
  end
end
