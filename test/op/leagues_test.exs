defmodule OP.LeaguesTest do
  use OP.DataCase

  import OP.PlayersFixtures
  import OP.LeaguesFixtures

  alias OP.Accounts.Scope
  alias OP.Leagues

  describe "list_rankings_by_player/2" do
    test "returns rankings for a player with preloaded season and league" do
      player = player_fixture()
      league = league_fixture()
      season = season_fixture(league)
      ranking = ranking_fixture(player, season, %{ranking: 2, total_points: 150.0})

      [result] = Leagues.list_rankings_by_player(Scope.for_user(nil), player.id)

      assert result.id == ranking.id
      assert result.ranking == 2
      assert result.total_points == 150.0
      assert result.season.id == season.id
      assert result.season.league.id == league.id
    end

    test "returns empty list when player has no rankings" do
      player = player_fixture()

      assert Leagues.list_rankings_by_player(Scope.for_user(nil), player.id) == []
    end

    test "orders rankings by ranking position ascending" do
      player = player_fixture()
      league = league_fixture()
      season1 = season_fixture(league)
      season2 = season_fixture(league)

      ranking_fixture(player, season1, %{ranking: 3})
      ranking_fixture(player, season2, %{ranking: 1})

      results = Leagues.list_rankings_by_player(Scope.for_user(nil), player.id)

      assert [first, second] = results
      assert first.ranking == 1
      assert second.ranking == 3
    end
  end
end
