defmodule OP.MatchplayFixtures do
  @moduledoc """
  Test fixtures for Matchplay API responses and player mappings.

  Note: The Matchplay API returns player data in two places:
  - Tournament endpoint with `?includePlayers=true` returns a `players` array
    with `playerId`, `name`, and `claimedBy` (global userId)
  - Standings endpoint returns only `playerId` and `position` (no names)

  The import process joins these two responses to get complete player info.
  """

  @doc """
  Returns a sample Matchplay tournament API response with players and location included.

  The `players` array contains the player names and IDs needed for import.
  The `location` object contains venue information from Matchplay.
  """
  def tournament_response(attrs \\ %{}) do
    # Extract players and location from attrs or use defaults
    players = Map.get(attrs, "players", default_tournament_players())
    location = Map.get(attrs, "location", default_location())

    attrs_without_extracted =
      attrs
      |> Map.delete("players")
      |> Map.delete("location")

    Map.merge(
      %{
        "tournamentId" => 12345,
        "name" => "Test Tournament",
        "startUtc" => "2024-03-15T18:00:00Z",
        "endUtc" => "2024-03-15T22:00:00Z",
        "link" => "https://app.matchplay.events/tournaments/12345",
        "status" => "completed",
        "players" => players,
        "location" => location
      },
      attrs_without_extracted
    )
  end

  @doc """
  Returns a sample Matchplay standings API response.

  Note: The real API only returns `playerId` and `position`, not names.
  Names come from the tournament's `players` array instead.

  Takes a list of standings maps or `{player_id, position}` tuples, or uses defaults.
  """
  def standings_response(standings \\ nil) do
    standings = standings || default_standings()

    Enum.map(standings, fn
      {player_id, position} ->
        %{"playerId" => player_id, "position" => position}

      %{} = standing ->
        standing
    end)
  end

  @doc """
  Returns a single standing entry for the API response (real format without name).
  """
  def standing_entry(player_id, position) do
    %{"playerId" => player_id, "position" => position}
  end

  @doc """
  Default players array for tournament response.

  Each player has:
  - `playerId` - tournament-specific ID used in standings
  - `name` - player's display name
  - `claimedBy` - global Matchplay userId (nil if unclaimed)
  """
  def default_tournament_players do
    [
      %{"playerId" => 101, "name" => "Alice Smith", "claimedBy" => 1001},
      %{"playerId" => 102, "name" => "Bob Jones", "claimedBy" => 1002},
      %{"playerId" => 103, "name" => "Charlie Brown", "claimedBy" => 1003}
    ]
  end

  @doc """
  Default standings list.
  """
  def default_standings do
    [
      %{"playerId" => 101, "position" => 1},
      %{"playerId" => 102, "position" => 2},
      %{"playerId" => 103, "position" => 3}
    ]
  end

  @doc """
  Default location data from Matchplay API.
  """
  def default_location do
    %{
      "locationId" => 6201,
      "name" => "Test Arcade",
      "address" => "123 Main St, Portland, OR 97201"
    }
  end

  @doc """
  Creates a tournament player entry.
  """
  def tournament_player(player_id, name, claimed_by \\ nil) do
    %{"playerId" => player_id, "name" => name, "claimedBy" => claimed_by}
  end

  @doc """
  Returns a player mapping struct for testing.
  """
  def player_mapping_fixture(attrs \\ %{}) do
    position = Map.get(attrs, :position, 1)

    Map.merge(
      %{
        matchplay_player_id: 1001,
        matchplay_name: "Alice Smith",
        position: position,
        qualifying_position: Map.get(attrs, :qualifying_position, position),
        finals_position: Map.get(attrs, :finals_position, nil),
        is_finalist: Map.get(attrs, :is_finalist, false),
        match_type: :unmatched,
        local_player_id: nil,
        local_player: nil,
        suggested_players: []
      },
      attrs
    )
  end

  @doc """
  Returns a full preview result structure for testing.
  """
  def preview_result_fixture(attrs \\ %{}) do
    tournament = Map.get(attrs, :tournament, tournament_response())
    player_mappings = Map.get(attrs, :player_mappings, [player_mapping_fixture()])
    location_data = Map.get(attrs, :location_data, default_location())
    matched_location = Map.get(attrs, :matched_location, nil)

    %{
      tournament: tournament,
      player_mappings: player_mappings,
      location_data: location_data,
      matched_location: matched_location
    }
  end

  @doc """
  Creates a location data fixture for Matchplay API response.
  """
  def matchplay_location_fixture(attrs \\ %{}) do
    Map.merge(default_location(), attrs)
  end
end
