defmodule OP.Tournaments.Import do
  @moduledoc """
  Orchestrates tournament import from Matchplay API.

  The import process is split into two steps:
  1. `fetch_tournament_preview/2` - Fetches tournament data and analyzes player mappings
  2. `execute_import/4` - Executes the import with confirmed player mappings
  """

  import Ecto.Query, warn: false

  alias OP.Matchplay.Client
  alias OP.Players
  alias OP.Players.Player
  alias OP.Repo
  alias OP.Tournaments
  alias OP.Tournaments.Standing

  @type player_mapping :: %{
          matchplay_player_id: integer() | String.t(),
          matchplay_name: String.t(),
          position: integer(),
          match_type: :auto | :suggested | :unmatched | :create_new | :manual,
          local_player_id: integer() | nil,
          local_player: Player.t() | nil,
          suggested_players: [Player.t()]
        }

  @type preview_result :: %{
          tournament: map(),
          player_mappings: [player_mapping()]
        }

  @type import_result :: %{
          tournament: Tournaments.Tournament.t(),
          players_created: non_neg_integer(),
          players_updated: non_neg_integer(),
          standings_count: non_neg_integer(),
          is_new: boolean()
        }

  @doc """
  Fetches tournament preview from Matchplay and analyzes player mappings.

  For each player in the standings:
  - Auto-matches if a player with `matchplay:{userId}` external_id exists
  - Suggests players with matching names
  - Marks as unmatched if no matches found

  ## Options
    * `:api_token` - Override the configured API token

  ## Returns
    * `{:ok, %{tournament: map(), player_mappings: [player_mapping()]}}` on success
    * `{:error, reason}` on failure
  """
  @spec fetch_tournament_preview(String.t() | integer(), keyword()) ::
          {:ok, preview_result()} | {:error, term()}
  def fetch_tournament_preview(matchplay_id, opts \\ []) do
    client = Client.new(Keyword.take(opts, [:api_token]))

    with {:ok, tournament} <- Client.get_tournament(client, matchplay_id),
         {:ok, standings} <- Client.get_standings(client, matchplay_id) do
      player_mappings = analyze_player_mappings(standings)

      {:ok,
       %{
         tournament: tournament,
         player_mappings: player_mappings
       }}
    end
  end

  @doc """
  Executes the import with confirmed player mappings.

  ## Arguments
    * `scope` - The current user scope
    * `tournament_data` - The tournament data from Matchplay
    * `player_mappings` - The confirmed player mappings with resolved `local_player_id` or `match_type: :create_new`
    * `opts` - Additional options

  ## Returns
    * `{:ok, import_result()}` on success
    * `{:error, reason}` on failure
  """
  @spec execute_import(term(), map(), [player_mapping()], keyword()) ::
          {:ok, import_result()} | {:error, term()}
  def execute_import(scope, tournament_data, player_mappings, opts \\ []) do
    matchplay_id = tournament_data["tournamentId"]
    external_id = "matchplay:#{matchplay_id}"

    Repo.transaction(fn ->
      # Find or prepare tournament
      existing_tournament = Tournaments.get_tournament_by_external_id(scope, external_id)
      is_new = is_nil(existing_tournament)

      # Process players and build ID map
      {players_created, players_updated, player_id_map} =
        process_players(scope, player_mappings, opts)

      # Create or update tournament
      tournament = upsert_tournament(scope, external_id, tournament_data, existing_tournament)

      # Delete existing standings if re-importing
      if not is_new do
        Tournaments.delete_standings_by_tournament_id(scope, tournament.id)
      end

      # Create standings
      standings_count = create_standings(tournament, player_mappings, player_id_map)

      %{
        tournament: tournament,
        players_created: players_created,
        players_updated: players_updated,
        standings_count: standings_count,
        is_new: is_new
      }
    end)
  end

  # Private functions

  defp analyze_player_mappings(standings) do
    Enum.map(standings, fn standing ->
      # Prefer userId over playerId
      matchplay_id = standing["userId"] || standing["playerId"]
      external_id = "matchplay:#{matchplay_id}"
      name = standing["name"] || ""
      position = standing["position"]

      # Try to find existing player by external_id
      case Players.get_player_by_external_id(nil, external_id) do
        %Player{} = player ->
          %{
            matchplay_player_id: matchplay_id,
            matchplay_name: name,
            position: position,
            match_type: :auto,
            local_player_id: player.id,
            local_player: player,
            suggested_players: []
          }

        nil ->
          # Try to find by exact name match
          suggested = find_players_by_name(name)

          match_type =
            case suggested do
              [_single] -> :suggested
              _ -> :unmatched
            end

          %{
            matchplay_player_id: matchplay_id,
            matchplay_name: name,
            position: position,
            match_type: match_type,
            local_player_id: nil,
            local_player: nil,
            suggested_players: suggested
          }
      end
    end)
  end

  defp find_players_by_name(name) when is_binary(name) and byte_size(name) > 0 do
    Player
    |> where([p], p.name == ^name)
    |> limit(5)
    |> Repo.all()
  end

  defp find_players_by_name(_), do: []

  defp process_players(scope, player_mappings, _opts) do
    Enum.reduce(player_mappings, {0, 0, %{}}, fn mapping, {created, updated, id_map} ->
      matchplay_id = mapping.matchplay_player_id
      external_id = "matchplay:#{matchplay_id}"

      case mapping.match_type do
        :create_new ->
          # Create a new player
          {:ok, player} =
            Players.create_player(scope, %{
              name: mapping.matchplay_name,
              external_id: external_id
            })

          {created + 1, updated, Map.put(id_map, matchplay_id, player.id)}

        type when type in [:auto, :suggested, :manual] ->
          # Use the mapped local player
          player_id = mapping.local_player_id

          # Update external_id if not already set
          player = Players.get_player!(scope, player_id)

          if is_nil(player.external_id) or player.external_id == "" do
            {:ok, _} = Players.update_player(scope, player, %{external_id: external_id})
          end

          {created, updated + 1, Map.put(id_map, matchplay_id, player_id)}

        :unmatched ->
          # This shouldn't happen if UI enforces all players are mapped
          # But handle gracefully by creating a new player
          {:ok, player} =
            Players.create_player(scope, %{
              name: mapping.matchplay_name,
              external_id: external_id
            })

          {created + 1, updated, Map.put(id_map, matchplay_id, player.id)}
      end
    end)
  end

  defp upsert_tournament(scope, external_id, tournament_data, existing) do
    attrs = %{
      external_id: external_id,
      external_url: tournament_data["link"],
      name: tournament_data["name"],
      start_at: parse_datetime(tournament_data["startUtc"]),
      end_at: parse_datetime(tournament_data["endUtc"])
    }

    case existing do
      nil ->
        {:ok, tournament} = Tournaments.create_tournament(scope, attrs)
        tournament

      tournament ->
        {:ok, tournament} = Tournaments.update_tournament(scope, tournament, attrs)
        tournament
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      {:error, _} -> nil
    end
  end

  defp create_standings(tournament, player_mappings, player_id_map) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    standings_attrs =
      Enum.map(player_mappings, fn mapping ->
        player_id = Map.fetch!(player_id_map, mapping.matchplay_player_id)

        %{
          tournament_id: tournament.id,
          player_id: player_id,
          position: mapping.position,
          is_finals: false,
          opted_out: false,
          inserted_at: now,
          updated_at: now
        }
      end)

    {count, _} = Repo.insert_all(Standing, standings_attrs)
    count
  end
end
