defmodule OP.Leagues.RankingCalculatorTest do
  use OP.DataCase, async: true

  alias OP.Leagues
  alias OP.Leagues.RankingCalculator

  import OP.LeaguesFixtures
  import OP.PlayersFixtures
  import OP.TournamentsFixtures

  describe "recalculate_season_rankings/1" do
    test "returns {:ok, 0} when season has no tournaments" do
      league = league_fixture()
      season = season_fixture(league)

      assert {:ok, 0} = RankingCalculator.recalculate_season_rankings(season.id)
    end

    test "returns {:ok, 0} when season has tournament but no standings" do
      league = league_fixture()
      season = season_fixture(league)
      _tournament = tournament_fixture(nil, %{season_id: season.id})

      assert {:ok, 0} = RankingCalculator.recalculate_season_rankings(season.id)
    end

    test "creates rankings from tournament standings" do
      league = league_fixture()
      season = season_fixture(league)
      tournament = tournament_fixture(nil, %{season_id: season.id})

      player1 = player_fixture()
      player2 = player_fixture()
      player3 = player_fixture()

      standing_fixture(tournament, player1, %{position: 1, total_points: 100.0})
      standing_fixture(tournament, player2, %{position: 2, total_points: 75.0})
      standing_fixture(tournament, player3, %{position: 3, total_points: 50.0})

      assert {:ok, 3} = RankingCalculator.recalculate_season_rankings(season.id)

      rankings = Leagues.list_rankings_by_season(nil, season.id)
      assert length(rankings) == 3

      [first, second, third] = rankings
      assert first.player_id == player1.id
      assert first.total_points == 100.0
      assert first.event_count == 1
      assert first.ranking == 1

      assert second.player_id == player2.id
      assert second.total_points == 75.0
      assert second.event_count == 1
      assert second.ranking == 2

      assert third.player_id == player3.id
      assert third.total_points == 50.0
      assert third.event_count == 1
      assert third.ranking == 3
    end

    test "aggregates points from multiple tournaments" do
      league = league_fixture()
      season = season_fixture(league)
      tournament1 = tournament_fixture(nil, %{season_id: season.id})
      tournament2 = tournament_fixture(nil, %{season_id: season.id})

      player1 = player_fixture()
      player2 = player_fixture()

      # Tournament 1: player1 wins
      standing_fixture(tournament1, player1, %{position: 1, total_points: 100.0})
      standing_fixture(tournament1, player2, %{position: 2, total_points: 75.0})

      # Tournament 2: player2 wins
      standing_fixture(tournament2, player2, %{position: 1, total_points: 100.0})
      standing_fixture(tournament2, player1, %{position: 2, total_points: 75.0})

      assert {:ok, 2} = RankingCalculator.recalculate_season_rankings(season.id)

      rankings = Leagues.list_rankings_by_season(nil, season.id)
      assert length(rankings) == 2

      [first, second] = rankings
      # Both players have 175 total points, order depends on db
      assert first.total_points == 175.0
      assert first.event_count == 2
      assert first.ranking == 1

      assert second.total_points == 175.0
      assert second.event_count == 2
      assert second.ranking == 2
    end

    test "updates existing rankings on recalculation" do
      league = league_fixture()
      season = season_fixture(league)
      tournament = tournament_fixture(nil, %{season_id: season.id})

      player1 = player_fixture()
      player2 = player_fixture()

      standing1 = standing_fixture(tournament, player1, %{position: 1, total_points: 100.0})
      standing_fixture(tournament, player2, %{position: 2, total_points: 75.0})

      # Initial calculation
      assert {:ok, 2} = RankingCalculator.recalculate_season_rankings(season.id)

      rankings = Leagues.list_rankings_by_season(nil, season.id)
      first_ranking = Enum.find(rankings, &(&1.player_id == player1.id))
      assert first_ranking.total_points == 100.0

      # Update standing points
      standing1
      |> Ecto.Changeset.change(%{total_points: 200.0})
      |> OP.Repo.update!()

      # Recalculate
      assert {:ok, 2} = RankingCalculator.recalculate_season_rankings(season.id)

      rankings = Leagues.list_rankings_by_season(nil, season.id)
      updated_ranking = Enum.find(rankings, &(&1.player_id == player1.id))
      assert updated_ranking.total_points == 200.0
    end

    test "only includes tournaments from the specified season" do
      league = league_fixture()
      season1 = season_fixture(league)
      season2 = season_fixture(league)

      tournament1 = tournament_fixture(nil, %{season_id: season1.id})
      tournament2 = tournament_fixture(nil, %{season_id: season2.id})

      player = player_fixture()

      standing_fixture(tournament1, player, %{position: 1, total_points: 100.0})
      standing_fixture(tournament2, player, %{position: 1, total_points: 200.0})

      # Calculate season1 rankings
      assert {:ok, 1} = RankingCalculator.recalculate_season_rankings(season1.id)

      rankings = Leagues.list_rankings_by_season(nil, season1.id)
      assert length(rankings) == 1
      assert hd(rankings).total_points == 100.0

      # Calculate season2 rankings
      assert {:ok, 1} = RankingCalculator.recalculate_season_rankings(season2.id)

      rankings = Leagues.list_rankings_by_season(nil, season2.id)
      assert length(rankings) == 1
      assert hd(rankings).total_points == 200.0
    end
  end

  describe "aggregate_season_standings/1" do
    test "returns empty list when no standings exist" do
      league = league_fixture()
      season = season_fixture(league)

      assert [] = RankingCalculator.aggregate_season_standings(season.id)
    end

    test "returns aggregated data sorted by total_points descending" do
      league = league_fixture()
      season = season_fixture(league)
      tournament = tournament_fixture(nil, %{season_id: season.id})

      player1 = player_fixture()
      player2 = player_fixture()

      standing_fixture(tournament, player1, %{position: 2, total_points: 50.0})
      standing_fixture(tournament, player2, %{position: 1, total_points: 100.0})

      result = RankingCalculator.aggregate_season_standings(season.id)

      assert length(result) == 2
      [first, second] = result

      assert first.player_id == player2.id
      assert first.total_points == 100.0

      assert second.player_id == player1.id
      assert second.total_points == 50.0
    end
  end
end
