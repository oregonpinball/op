defmodule OP.Tournaments.ImportTest do
  use OP.DataCase

  alias OP.Players
  alias OP.Repo
  alias OP.Tournaments.Import
  alias OP.Tournaments.Standing

  import OP.AccountsFixtures
  import OP.MatchplayFixtures
  import OP.PlayersFixtures
  import OP.TournamentsFixtures

  describe "fetch_tournament_preview/2" do
    test "returns error when API token is not configured" do
      assert {:error, :api_token_required} =
               Import.fetch_tournament_preview("12345", api_token: nil)
    end

    test "returns error when API token is empty string" do
      assert {:error, :api_token_required} =
               Import.fetch_tournament_preview("12345", api_token: "")
    end
  end

  describe "execute_import/4" do
    setup do
      scope = user_scope_fixture()
      %{scope: scope}
    end

    test "creates new tournament and players when none exist", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 99999})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 2001,
          matchplay_name: "New Player One",
          position: 1,
          match_type: :create_new
        }),
        player_mapping_fixture(%{
          matchplay_player_id: 2002,
          matchplay_name: "New Player Two",
          position: 2,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.is_new == true
      assert result.players_created == 2
      assert result.players_updated == 0
      assert result.standings_count == 2
      assert result.tournament.name == "Test Tournament"
      assert result.tournament.external_id == "matchplay:99999"
    end

    test "updates existing tournament when external_id matches", %{scope: scope} do
      existing =
        tournament_with_external_id_fixture(scope, "matchplay:12345", %{name: "Old Name"})

      tournament_data =
        tournament_response(%{
          "tournamentId" => 12345,
          "name" => "Updated Name"
        })

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 2001,
          matchplay_name: "Player One",
          position: 1,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.is_new == false
      assert result.tournament.id == existing.id
      assert result.tournament.name == "Updated Name"
    end

    test "maps auto-matched players by external_id", %{scope: scope} do
      existing_player =
        player_with_external_id_fixture(scope, "matchplay:3001", %{name: "Existing Player"})

      tournament_data = tournament_response(%{"tournamentId" => 55555})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 3001,
          matchplay_name: "Existing Player",
          position: 1,
          match_type: :auto,
          local_player_id: existing_player.id,
          local_player: existing_player
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.players_created == 0
      assert result.players_updated == 1
      assert result.standings_count == 1
    end

    test "handles manually mapped players and sets external_id", %{scope: scope} do
      existing_player = player_fixture(scope, %{name: "Manual Match"})

      tournament_data = tournament_response(%{"tournamentId" => 66666})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 4001,
          matchplay_name: "Matchplay Name",
          position: 1,
          match_type: :manual,
          local_player_id: existing_player.id,
          local_player: existing_player
        })
      ]

      assert {:ok, _result} = Import.execute_import(scope, tournament_data, player_mappings)

      # Check that external_id was updated on the player
      updated_player = Players.get_player!(scope, existing_player.id)
      assert updated_player.external_id == "matchplay:4001"
    end

    test "handles suggested player mappings", %{scope: scope} do
      existing_player = player_fixture(scope, %{name: "Suggested Match"})

      tournament_data = tournament_response(%{"tournamentId" => 77777})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 5001,
          matchplay_name: "Suggested Match",
          position: 1,
          match_type: :suggested,
          local_player_id: existing_player.id,
          local_player: existing_player
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.players_updated == 1
    end

    test "handles unmatched players by creating new ones", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 88888})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 6001,
          matchplay_name: "Unmatched Player",
          position: 1,
          match_type: :unmatched
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.players_created == 1
    end

    test "deletes existing standings when re-importing", %{scope: scope} do
      tournament = tournament_with_external_id_fixture(scope, "matchplay:11111")
      player = player_fixture(scope)
      _standing = standing_fixture(tournament, player, %{position: 1})

      # Verify standing exists
      assert Repo.aggregate(Standing, :count) == 1

      tournament_data = tournament_response(%{"tournamentId" => 11111})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 7001,
          matchplay_name: "New Standings Player",
          position: 1,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      # Verify old standings were deleted and new ones created
      assert result.standings_count == 1
      assert Repo.aggregate(Standing, :count) == 1
    end

    test "parses datetime strings correctly", %{scope: scope} do
      tournament_data =
        tournament_response(%{
          "tournamentId" => 22222,
          "startUtc" => "2024-06-15T14:30:00Z",
          "endUtc" => "2024-06-15T20:00:00Z"
        })

      player_mappings = [
        player_mapping_fixture(%{match_type: :create_new})
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.tournament.start_at == ~U[2024-06-15 14:30:00Z]
      assert result.tournament.end_at == ~U[2024-06-15 20:00:00Z]
    end

    test "handles nil datetime values", %{scope: scope} do
      tournament_data =
        tournament_response(%{
          "tournamentId" => 33333,
          "startUtc" => "2024-01-01T00:00:00Z",
          "endUtc" => nil
        })

      player_mappings = [
        player_mapping_fixture(%{match_type: :create_new})
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)
      assert result.tournament.end_at == nil
    end

    test "sets correct standing positions", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 44444})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 8001,
          matchplay_name: "First Place",
          position: 1,
          match_type: :create_new
        }),
        player_mapping_fixture(%{
          matchplay_player_id: 8002,
          matchplay_name: "Second Place",
          position: 2,
          match_type: :create_new
        }),
        player_mapping_fixture(%{
          matchplay_player_id: 8003,
          matchplay_name: "Third Place",
          position: 3,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.standings_count == 3

      # Verify standings have correct positions
      standings = Repo.all(Standing)
      positions = Enum.map(standings, & &1.position) |> Enum.sort()
      assert positions == [1, 2, 3]
    end

    test "handles mixed mapping types in single import", %{scope: scope} do
      # Create existing players for different match types
      auto_player =
        player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Auto Player"})

      manual_player = player_fixture(scope, %{name: "Manual Player"})

      tournament_data = tournament_response(%{"tournamentId" => 99998})

      player_mappings = [
        # Auto-matched
        player_mapping_fixture(%{
          matchplay_player_id: 1001,
          matchplay_name: "Auto Player",
          position: 1,
          match_type: :auto,
          local_player_id: auto_player.id,
          local_player: auto_player
        }),
        # Manually mapped
        player_mapping_fixture(%{
          matchplay_player_id: 1002,
          matchplay_name: "Different Name",
          position: 2,
          match_type: :manual,
          local_player_id: manual_player.id,
          local_player: manual_player
        }),
        # Create new
        player_mapping_fixture(%{
          matchplay_player_id: 1003,
          matchplay_name: "New Player",
          position: 3,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.players_created == 1
      assert result.players_updated == 2
      assert result.standings_count == 3

      # Verify manual player got external_id set
      updated_manual = Players.get_player!(scope, manual_player.id)
      assert updated_manual.external_id == "matchplay:1002"

      # Verify new player was created
      new_player = Players.get_player_by_external_id(scope, "matchplay:1003")
      assert new_player.name == "New Player"
    end

    test "sets external URL from tournament link", %{scope: scope} do
      tournament_data =
        tournament_response(%{
          "tournamentId" => 55550,
          "link" => "https://app.matchplay.events/tournaments/55550/standings"
        })

      player_mappings = [player_mapping_fixture(%{match_type: :create_new})]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.tournament.external_url ==
               "https://app.matchplay.events/tournaments/55550/standings"
    end

    test "handles empty player mappings", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 66660})

      assert {:ok, result} = Import.execute_import(scope, tournament_data, [])

      assert result.players_created == 0
      assert result.players_updated == 0
      assert result.standings_count == 0
      assert result.tournament.name == "Test Tournament"
    end
  end
end
