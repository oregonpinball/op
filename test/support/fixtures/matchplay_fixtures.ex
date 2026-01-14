defmodule OP.MatchplayFixtures do
  @moduledoc """
  Test fixtures for Matchplay API responses and player mappings.
  """

  @doc """
  Returns a sample Matchplay tournament API response.
  """
  def tournament_response(attrs \\ %{}) do
    Map.merge(
      %{
        "tournamentId" => 12345,
        "name" => "Test Tournament",
        "startUtc" => "2024-03-15T18:00:00Z",
        "endUtc" => "2024-03-15T22:00:00Z",
        "link" => "https://app.matchplay.events/tournaments/12345",
        "status" => "completed"
      },
      attrs
    )
  end

  @doc """
  Returns a sample Matchplay standings API response.

  Takes a list of `{user_id, name}` tuples, or uses defaults.
  """
  def standings_response(players \\ nil) do
    players = players || default_standings_players()

    players
    |> Enum.with_index(1)
    |> Enum.map(fn {{user_id, name}, position} ->
      %{
        "userId" => user_id,
        "name" => name,
        "position" => position
      }
    end)
  end

  @doc """
  Returns a single standing entry for the API response.
  """
  def standing_entry(user_id, name, position) do
    %{
      "userId" => user_id,
      "name" => name,
      "position" => position
    }
  end

  @doc """
  Default player list for standings.
  """
  def default_standings_players do
    [
      {1001, "Alice Smith"},
      {1002, "Bob Jones"},
      {1003, "Charlie Brown"}
    ]
  end

  @doc """
  Returns a player mapping struct for testing.
  """
  def player_mapping_fixture(attrs \\ %{}) do
    Map.merge(
      %{
        matchplay_player_id: 1001,
        matchplay_name: "Alice Smith",
        position: 1,
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

    %{
      tournament: tournament,
      player_mappings: player_mappings
    }
  end
end
