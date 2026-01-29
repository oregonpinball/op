defmodule OPWeb.SeasonControllerTest do
  use OPWeb.ConnCase

  import OP.PlayersFixtures
  import OP.LeaguesFixtures

  describe "GET /seasons/:slug" do
    test "shows season name and league name", %{conn: conn} do
      league = league_fixture(%{name: "Test League"})
      season = season_fixture(league, %{name: "Spring 2025"})

      conn = get(conn, ~p"/seasons/#{season.slug}")
      response = html_response(conn, 200)

      assert response =~ "Spring 2025"
      assert response =~ "Test League"
    end

    test "shows ranking data", %{conn: conn} do
      league = league_fixture(%{name: "Test League"})
      season = season_fixture(league, %{name: "Spring 2025"})
      player = player_fixture(nil, %{name: "Alice"})

      ranking_fixture(player, season, %{
        ranking: 1,
        rating: 1600.0,
        total_points: 250.0,
        event_count: 10
      })

      conn = get(conn, ~p"/seasons/#{season.slug}")
      response = html_response(conn, 200)

      assert response =~ "Alice"
      assert response =~ "1600"
      assert response =~ "250.0"
      assert response =~ "10"
    end

    test "shows empty state when no rankings", %{conn: conn} do
      league = league_fixture(%{name: "Test League"})
      season = season_fixture(league, %{name: "Empty Season"})

      conn = get(conn, ~p"/seasons/#{season.slug}")
      response = html_response(conn, 200)

      assert response =~ "Empty Season"
      assert response =~ "No rankings yet"
    end

    test "returns 404 for nonexistent slug", %{conn: conn} do
      conn = get(conn, ~p"/seasons/nonexistent-slug")
      assert html_response(conn, 404)
    end
  end
end
