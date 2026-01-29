defmodule OPWeb.PlayerControllerTest do
  use OPWeb.ConnCase

  import OP.PlayersFixtures
  import OP.LeaguesFixtures

  describe "GET /players/:slug" do
    test "shows player name", %{conn: conn} do
      player = player_fixture(nil, %{name: "Jane Doe"})
      conn = get(conn, ~p"/players/#{player.slug}")

      assert html_response(conn, 200) =~ "Jane Doe"
    end

    test "shows ranking data when player has rankings", %{conn: conn} do
      player = player_fixture(nil, %{name: "Ranked Player"})
      league = league_fixture(%{name: "Test League"})
      season = season_fixture(league, %{name: "Season 2025"})

      ranking_fixture(player, season, %{
        ranking: 1,
        rating: 1600.0,
        total_points: 250.0,
        event_count: 10
      })

      conn = get(conn, ~p"/players/#{player.slug}")
      response = html_response(conn, 200)

      assert response =~ "Ranked Player"
      assert response =~ "Season 2025"
      assert response =~ "Test League"
      assert response =~ "1600"
      assert response =~ "250.0"
      assert response =~ "10"
    end

    test "shows empty state when player has no rankings", %{conn: conn} do
      player = player_fixture(nil, %{name: "New Player"})
      conn = get(conn, ~p"/players/#{player.slug}")
      response = html_response(conn, 200)

      assert response =~ "New Player"
      assert response =~ "No rankings yet"
    end

    test "returns error for non-existent slug", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, ~p"/players/non-existent-slug")
      end
    end
  end
end
