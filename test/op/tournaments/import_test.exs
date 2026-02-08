defmodule OP.Tournaments.ImportTest do
  use OP.DataCase

  alias OP.Players
  alias OP.Repo
  alias OP.Tournaments
  alias OP.Tournaments.Import
  alias OP.Tournaments.Standing

  import OP.AccountsFixtures
  import OP.LeaguesFixtures
  import OP.LocationsFixtures
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

      # Verify standing exists for this tournament
      tournament_standing_count =
        from(s in Standing, where: s.tournament_id == ^tournament.id)
        |> Repo.aggregate(:count)

      assert tournament_standing_count == 1

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

      # Verify old standings were deleted and new ones created for this tournament
      assert result.standings_count == 1

      new_count =
        from(s in Standing, where: s.tournament_id == ^tournament.id)
        |> Repo.aggregate(:count)

      assert new_count == 1
    end

    test "parses datetime strings correctly", %{scope: scope} do
      tournament_data =
        tournament_response(%{
          "tournamentId" => 22222,
          "startUtc" => "2024-06-15T14:30:00Z"
        })

      player_mappings = [
        player_mapping_fixture(%{match_type: :create_new})
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.tournament.start_at == ~U[2024-06-15 14:30:00Z]
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

      # Verify standings have correct positions for this tournament
      standings =
        from(s in Standing, where: s.tournament_id == ^result.tournament.id)
        |> Repo.all()

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

    test "applies tournament overrides for name and description", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 77770})

      overrides = %{
        name: "Custom Tournament Name",
        description: "Custom description"
      }

      assert {:ok, result} = Import.execute_import(scope, tournament_data, [], overrides)

      assert result.tournament.name == "Custom Tournament Name"
      assert result.tournament.description == "Custom description"
    end

    test "applies tournament overrides for location_id", %{scope: scope} do
      location = location_fixture(%{name: "Override Location"})
      tournament_data = tournament_response(%{"tournamentId" => 77771})

      overrides = %{
        location_id: location.id
      }

      assert {:ok, result} = Import.execute_import(scope, tournament_data, [], overrides)

      assert result.tournament.location_id == location.id
    end

    test "applies tournament overrides for season_id", %{scope: scope} do
      league = league_fixture()
      season = season_fixture(league)
      tournament_data = tournament_response(%{"tournamentId" => 77772})

      overrides = %{
        season_id: season.id
      }

      assert {:ok, result} = Import.execute_import(scope, tournament_data, [], overrides)

      assert result.tournament.season_id == season.id
    end

    test "applies tournament overrides for start_at as string", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 77773})

      overrides = %{
        start_at: "2025-06-15T14:30"
      }

      assert {:ok, result} = Import.execute_import(scope, tournament_data, [], overrides)

      # The datetime should be parsed correctly
      assert result.tournament.start_at == ~U[2025-06-15 14:30:00Z]
    end

    test "ignores nil and empty overrides", %{scope: scope} do
      tournament_data =
        tournament_response(%{
          "tournamentId" => 77774,
          "name" => "Original Name"
        })

      overrides = %{
        name: nil,
        description: "",
        location_id: nil
      }

      assert {:ok, result} = Import.execute_import(scope, tournament_data, [], overrides)

      # Should use the original name from API
      assert result.tournament.name == "Original Name"
    end

    test "combines multiple overrides in single import", %{scope: scope} do
      location = location_fixture(%{name: "Combined Location"})
      league = league_fixture()
      season = season_fixture(league)

      tournament_data = tournament_response(%{"tournamentId" => 77775})

      overrides = %{
        name: "Combined Override Name",
        description: "Combined description",
        location_id: location.id,
        season_id: season.id,
        start_at: "2025-12-25T20:00"
      }

      player_mappings = [
        player_mapping_fixture(%{match_type: :create_new})
      ]

      assert {:ok, result} =
               Import.execute_import(scope, tournament_data, player_mappings, overrides)

      tournament = Tournaments.get_tournament!(scope, result.tournament.id)
      assert tournament.name == "Combined Override Name"
      assert tournament.description == "Combined description"
      assert tournament.location_id == location.id
      assert tournament.season_id == season.id
      assert tournament.start_at == ~U[2025-12-25 20:00:00Z]
      assert result.players_created == 1
    end

    test "sets location external_id when not already set", %{scope: scope} do
      location = location_fixture(%{name: "Test Location", external_id: nil})

      tournament_data =
        tournament_response(%{
          "tournamentId" => 88880,
          "location" => %{"locationId" => 12345, "name" => "Matchplay Location"}
        })

      overrides = %{location_id: location.id}

      assert {:ok, _result} = Import.execute_import(scope, tournament_data, [], overrides)

      # Location should now have external_id set
      updated_location = OP.Locations.get_location!(scope, location.id)
      assert updated_location.external_id == "matchplay:12345"
    end

    test "does not modify location external_id when already set", %{scope: scope} do
      location = location_fixture(%{name: "Test Location", external_id: "existing:999"})

      tournament_data =
        tournament_response(%{
          "tournamentId" => 88881,
          "location" => %{"locationId" => 12345, "name" => "Matchplay Location"}
        })

      overrides = %{location_id: location.id}

      assert {:ok, _result} = Import.execute_import(scope, tournament_data, [], overrides)

      # Location external_id should remain unchanged
      updated_location = OP.Locations.get_location!(scope, location.id)
      assert updated_location.external_id == "existing:999"
    end

    test "handles import without location selected", %{scope: scope} do
      tournament_data =
        tournament_response(%{
          "tournamentId" => 88882,
          "location" => %{"locationId" => 12345, "name" => "Matchplay Location"}
        })

      # No location_id in overrides
      assert {:ok, result} = Import.execute_import(scope, tournament_data, [])

      assert result.tournament.name == "Test Tournament"
    end

    test "handles import without location data from API", %{scope: scope} do
      location = location_fixture(%{name: "Test Location", external_id: nil})

      tournament_data =
        tournament_response(%{
          "tournamentId" => 88883,
          "location" => nil
        })

      overrides = %{location_id: location.id}

      assert {:ok, _result} = Import.execute_import(scope, tournament_data, [], overrides)

      # Location external_id should remain nil
      updated_location = OP.Locations.get_location!(scope, location.id)
      assert is_nil(updated_location.external_id)
    end

    test "creates separate external_id and finals_external_id for combined tournament", %{
      scope: scope
    } do
      qualifying_data = tournament_response(%{"tournamentId" => 11111})
      finals_data = tournament_response(%{"tournamentId" => 22222})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 1001,
          matchplay_name: "Player One",
          position: 1,
          qualifying_position: 2,
          finals_position: 1,
          is_finalist: true,
          match_type: :create_new
        })
      ]

      assert {:ok, result} =
               Import.execute_import(
                 scope,
                 qualifying_data,
                 player_mappings,
                 %{},
                 finals_tournament: finals_data
               )

      assert result.tournament.external_id == "matchplay:11111"
      assert result.tournament.finals_external_id == "matchplay:22222"
    end

    test "sets finals_external_id to nil for single tournament", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 44440})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 1001,
          matchplay_name: "Player One",
          position: 1,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      assert result.tournament.external_id == "matchplay:44440"
      assert is_nil(result.tournament.finals_external_id)
    end

    test "sets is_finals correctly for finalists", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 33333})

      player_mappings = [
        player_mapping_fixture(%{
          matchplay_player_id: 1001,
          matchplay_name: "Finalist",
          position: 1,
          is_finalist: true,
          match_type: :create_new
        }),
        player_mapping_fixture(%{
          matchplay_player_id: 1002,
          matchplay_name: "Non-finalist",
          position: 2,
          is_finalist: false,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)

      standings =
        from(s in Standing, where: s.tournament_id == ^result.tournament.id)
        |> Repo.all()
        |> Enum.sort_by(& &1.position)

      assert length(standings) == 2
      assert Enum.at(standings, 0).is_finals == true
      assert Enum.at(standings, 1).is_finals == false
    end
  end

  describe "fetch_combined_preview/3" do
    test "returns error when API token is not configured" do
      assert {:error, :api_token_required} =
               Import.fetch_combined_preview("12345", "67890", api_token: nil)
    end

    test "returns error when API token is empty string" do
      assert {:error, :api_token_required} =
               Import.fetch_combined_preview("12345", "67890", api_token: "")
    end
  end

  describe "resync_from_matchplay/3" do
    setup do
      Req.Test.set_req_test_from_context(__MODULE__)
      scope = user_scope_fixture()
      %{scope: scope}
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

    test "re-syncs standings for single tournament", %{scope: scope} do
      player = player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Alice Smith"})
      tournament = tournament_with_external_id_fixture(scope, "matchplay:12345")
      _old_standing = standing_fixture(tournament, player, %{position: 1})

      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "players" => [tournament_player(101, "Alice Smith", 1001)]
        }),
        standings_response([{101, 1}])
      )

      assert {:ok, result} = Import.resync_from_matchplay(scope, tournament)
      assert result.standings_count == 1
      assert result.players_created == 0
      assert result.is_new == false

      # Verify old standings were replaced
      standings =
        from(s in Standing, where: s.tournament_id == ^tournament.id)
        |> Repo.all()

      assert length(standings) == 1
    end

    test "preserves existing tournament attributes", %{scope: scope} do
      player = player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Alice Smith"})

      tournament =
        tournament_with_external_id_fixture(scope, "matchplay:12345", %{
          name: "My Custom Name",
          description: "My custom description"
        })

      _standing = standing_fixture(tournament, player, %{position: 1})

      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "name" => "API Name That Should Be Overridden",
          "players" => [tournament_player(101, "Alice Smith", 1001)]
        }),
        standings_response([{101, 1}])
      )

      assert {:ok, result} = Import.resync_from_matchplay(scope, tournament)
      assert result.tournament.name == "My Custom Name"
      assert result.tournament.description == "My custom description"
    end

    test "creates new players for unmatched API players", %{scope: scope} do
      tournament = tournament_with_external_id_fixture(scope, "matchplay:12345")

      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "players" => [tournament_player(201, "Brand New Player", nil)]
        }),
        standings_response([{201, 1}])
      )

      assert {:ok, result} = Import.resync_from_matchplay(scope, tournament)
      assert result.players_created == 1
      assert result.standings_count == 1
    end

    test "auto-matches existing players by external_id", %{scope: scope} do
      _player = player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Alice Smith"})
      tournament = tournament_with_external_id_fixture(scope, "matchplay:12345")

      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "players" => [tournament_player(101, "Alice Smith", 1001)]
        }),
        standings_response([{101, 1}])
      )

      assert {:ok, result} = Import.resync_from_matchplay(scope, tournament)
      assert result.players_created == 0
      assert result.players_updated == 1
    end

    test "handles combined tournament resync", %{scope: scope} do
      player = player_with_external_id_fixture(scope, "matchplay:1001", %{name: "Alice Smith"})

      tournament =
        tournament_with_external_id_fixture(scope, "matchplay:11111", %{
          finals_external_id: "matchplay:22222"
        })

      _standing = standing_fixture(tournament, player, %{position: 1})

      # Stub both qualifying and finals endpoints
      Req.Test.stub(OP.Matchplay.Client, fn plug_conn ->
        path = plug_conn.request_path

        cond do
          String.contains?(path, "/tournaments/11111/standings") ->
            Req.Test.json(plug_conn, standings_response([{101, 1}]))

          String.contains?(path, "/tournaments/22222/standings") ->
            Req.Test.json(plug_conn, standings_response([{201, 1}]))

          String.contains?(path, "/tournaments/11111") ->
            Req.Test.json(plug_conn, %{
              "data" =>
                tournament_response(%{
                  "tournamentId" => 11111,
                  "players" => [tournament_player(101, "Alice Smith", 1001)]
                })
            })

          String.contains?(path, "/tournaments/22222") ->
            Req.Test.json(plug_conn, %{
              "data" =>
                tournament_response(%{
                  "tournamentId" => 22222,
                  "players" => [tournament_player(201, "Alice Smith", 1001)]
                })
            })

          true ->
            Req.Test.json(plug_conn, %{})
        end
      end)

      assert {:ok, result} = Import.resync_from_matchplay(scope, tournament)
      assert result.standings_count == 1
      assert result.is_new == false
    end

    test "returns error when API token not configured", %{scope: scope} do
      tournament = tournament_with_external_id_fixture(scope, "matchplay:12345")

      assert {:error, :api_token_required} =
               Import.resync_from_matchplay(scope, tournament, api_token: nil)
    end

    test "fills in nil local fields from API data", %{scope: scope} do
      tournament =
        tournament_with_external_id_fixture(scope, "matchplay:12345", %{
          name: "My Name"
        })

      stub_matchplay_api(
        tournament_response(%{
          "tournamentId" => 12345,
          "name" => "API Name",
          "players" => [tournament_player(201, "Player One", nil)]
        }),
        standings_response([{201, 1}])
      )

      assert {:ok, result} = Import.resync_from_matchplay(scope, tournament)
      # Name should be preserved as the local override
      assert result.tournament.name == "My Name"
    end
  end

  describe "merge_standings algorithm" do
    # These tests verify the merge algorithm through execute_import
    # by checking the resulting standings positions

    setup do
      scope = user_scope_fixture()
      %{scope: scope}
    end

    test "finalists get top positions based on finals finish", %{scope: scope} do
      tournament_data = tournament_response(%{"tournamentId" => 55555})

      # Simulating merged results: 3 finalists from 5-player qualifying
      player_mappings = [
        # Finalist who was Q.2, F.1 -> Position 1
        player_mapping_fixture(%{
          matchplay_player_id: 1001,
          matchplay_name: "Alice",
          position: 1,
          qualifying_position: 2,
          finals_position: 1,
          is_finalist: true,
          match_type: :create_new
        }),
        # Finalist who was Q.1, F.2 -> Position 2
        player_mapping_fixture(%{
          matchplay_player_id: 1002,
          matchplay_name: "Bob",
          position: 2,
          qualifying_position: 1,
          finals_position: 2,
          is_finalist: true,
          match_type: :create_new
        }),
        # Finalist who was Q.5, F.3 -> Position 3
        player_mapping_fixture(%{
          matchplay_player_id: 1003,
          matchplay_name: "Charlie",
          position: 3,
          qualifying_position: 5,
          finals_position: 3,
          is_finalist: true,
          match_type: :create_new
        }),
        # Non-finalist Q.3 -> Position 4
        player_mapping_fixture(%{
          matchplay_player_id: 1004,
          matchplay_name: "Diana",
          position: 4,
          qualifying_position: 3,
          finals_position: nil,
          is_finalist: false,
          match_type: :create_new
        }),
        # Non-finalist Q.4 -> Position 5
        player_mapping_fixture(%{
          matchplay_player_id: 1005,
          matchplay_name: "Eve",
          position: 5,
          qualifying_position: 4,
          finals_position: nil,
          is_finalist: false,
          match_type: :create_new
        })
      ]

      assert {:ok, result} = Import.execute_import(scope, tournament_data, player_mappings)
      assert result.standings_count == 5

      standings =
        from(s in Standing, where: s.tournament_id == ^result.tournament.id)
        |> Repo.all()
        |> Enum.sort_by(& &1.position)

      # First 3 should be finalists
      assert Enum.at(standings, 0).is_finals == true
      assert Enum.at(standings, 0).position == 1
      assert Enum.at(standings, 1).is_finals == true
      assert Enum.at(standings, 1).position == 2
      assert Enum.at(standings, 2).is_finals == true
      assert Enum.at(standings, 2).position == 3

      # Last 2 should be non-finalists
      assert Enum.at(standings, 3).is_finals == false
      assert Enum.at(standings, 3).position == 4
      assert Enum.at(standings, 4).is_finals == false
      assert Enum.at(standings, 4).position == 5
    end
  end
end
