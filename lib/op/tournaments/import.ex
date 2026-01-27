defmodule OP.Tournaments.Import do
  @moduledoc """
  Orchestrates tournament import from Matchplay API.

  The import process is split into two steps:
  1. `fetch_tournament_preview/2` - Fetches tournament data and analyzes player mappings
  2. `execute_import/5` - Executes the import with confirmed player mappings and overrides
  """

  import Ecto.Query, warn: false

  alias OP.Locations
  alias OP.Matchplay.Client
  alias OP.Players
  alias OP.Players.Player
  alias OP.Repo
  alias OP.Tournaments
  alias OP.Tournaments.Standing
  alias OP.Tournaments.TgpCalculator
  alias OP.Leagues

  @type player_mapping :: %{
          matchplay_player_id: integer() | String.t(),
          matchplay_name: String.t(),
          position: integer(),
          qualifying_position: integer(),
          finals_position: integer() | nil,
          is_finalist: boolean(),
          match_type: :auto | :suggested | :unmatched | :create_new | :manual,
          local_player_id: integer() | nil,
          local_player: Player.t() | nil,
          suggested_players: [Player.t()]
        }

  @type preview_result :: %{
          tournament: map(),
          player_mappings: [player_mapping()],
          location_data: map() | nil,
          matched_location: Locations.Location.t() | nil,
          location_created: boolean(),
          finals_tournament: map() | nil,
          finalist_count: non_neg_integer()
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

    # Require API token to be configured
    if is_nil(client.api_token) or client.api_token == "" do
      {:error, :api_token_required}
    else
      with {:ok, tournament} <- Client.get_tournament(client, matchplay_id),
           {:ok, standings} <- Client.get_standings(client, matchplay_id) do
        # Build a map of playerId -> player data from tournament.players
        players_map = build_players_map(tournament["players"] || [])

        player_mappings = analyze_player_mappings(standings, players_map)

        # Extract location info from API response and find or create location
        location_data = tournament["location"]

        case match_location_from_api(location_data) do
          {:ok, matched_location, location_created} ->
            {:ok,
             %{
               tournament: tournament,
               player_mappings: player_mappings,
               location_data: location_data,
               matched_location: matched_location,
               location_created: location_created,
               finals_tournament: nil,
               finalist_count: 0
             }}

          {:error, _changeset} = error ->
            error
        end
      end
    end
  end

  @doc """
  Fetches combined tournament preview for qualifying + finals tournaments.

  Fetches both tournaments in parallel, then merges standings:
  - Finals players get positions 1-N based on their finals finish
  - Non-finalists retain their qualifying order, shifted to positions (N+1) and beyond
  - All finals players must appear in qualifying standings

  ## Options
    * `:api_token` - Override the configured API token

  ## Returns
    * `{:ok, preview_result()}` on success
    * `{:error, {:finals_players_not_in_qualifying, [String.t()]}}` if finals players don't exist in qualifying
    * `{:error, reason}` on failure
  """
  @spec fetch_combined_preview(String.t() | integer(), String.t() | integer(), keyword()) ::
          {:ok, preview_result()} | {:error, term()}
  def fetch_combined_preview(qualifying_id, finals_id, opts \\ []) do
    client = Client.new(Keyword.take(opts, [:api_token]))

    if is_nil(client.api_token) or client.api_token == "" do
      {:error, :api_token_required}
    else
      # Fetch both tournaments in parallel
      qualifying_task =
        Task.async(fn ->
          with {:ok, tournament} <- Client.get_tournament(client, qualifying_id),
               {:ok, standings} <- Client.get_standings(client, qualifying_id) do
            {:ok, {tournament, standings}}
          end
        end)

      finals_task =
        Task.async(fn ->
          with {:ok, tournament} <- Client.get_tournament(client, finals_id),
               {:ok, standings} <- Client.get_standings(client, finals_id) do
            {:ok, {tournament, standings}}
          end
        end)

      with {:ok, {qualifying_tournament, qualifying_standings}} <- Task.await(qualifying_task),
           {:ok, {finals_tournament, finals_standings}} <- Task.await(finals_task) do
        # Build players maps
        qualifying_players_map = build_players_map(qualifying_tournament["players"] || [])
        finals_players_map = build_players_map(finals_tournament["players"] || [])

        # Merge standings
        case merge_standings(
               qualifying_standings,
               finals_standings,
               qualifying_players_map,
               finals_players_map
             ) do
          {:ok, merged_standings, finalist_count} ->
            player_mappings = analyze_player_mappings_with_finals_info(merged_standings)

            # Extract location info from qualifying tournament
            location_data = qualifying_tournament["location"]

            case match_location_from_api(location_data) do
              {:ok, matched_location, location_created} ->
                {:ok,
                 %{
                   tournament: qualifying_tournament,
                   player_mappings: player_mappings,
                   location_data: location_data,
                   matched_location: matched_location,
                   location_created: location_created,
                   finals_tournament: finals_tournament,
                   finalist_count: finalist_count
                 }}

              {:error, _changeset} = error ->
                error
            end

          {:error, _} = error ->
            error
        end
      end
    end
  end

  @type tournament_overrides :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t(),
          optional(:start_at) => DateTime.t() | String.t(),
          optional(:location_id) => integer(),
          optional(:season_id) => integer(),
          optional(:meaningful_games) => float() | nil
        }

  @doc """
  Executes the import with confirmed player mappings and tournament overrides.

  ## Arguments
    * `scope` - The current user scope
    * `tournament_data` - The tournament data from Matchplay
    * `player_mappings` - The confirmed player mappings with resolved `local_player_id` or `match_type: :create_new`
    * `tournament_overrides` - User-provided overrides for tournament fields (name, description, start_at, location_id, season_id)
    * `opts` - Additional options

  ## Returns
    * `{:ok, import_result()}` on success
    * `{:error, reason}` on failure
  """
  @spec execute_import(term(), map(), [player_mapping()], tournament_overrides(), keyword()) ::
          {:ok, import_result()} | {:error, term()}
  def execute_import(
        scope,
        tournament_data,
        player_mappings,
        tournament_overrides \\ %{},
        opts \\ []
      ) do
    qualifying_id = tournament_data["tournamentId"]
    finals_tournament = Keyword.get(opts, :finals_tournament)

    external_id = "matchplay:#{qualifying_id}"

    finals_external_id =
      if finals_tournament do
        "matchplay:#{finals_tournament["tournamentId"]}"
      else
        nil
      end

    Repo.transaction(fn ->
      # Find or prepare tournament
      existing_tournament = Tournaments.get_tournament_by_external_id(scope, external_id)
      is_new = is_nil(existing_tournament)

      # Process players and build ID map
      {players_created, players_updated, player_id_map} =
        process_players(scope, player_mappings, opts)

      # Create or update tournament with overrides
      tournament =
        upsert_tournament(
          scope,
          external_id,
          finals_external_id,
          tournament_data,
          existing_tournament,
          tournament_overrides
        )

      # Update location external_id if not already set
      maybe_update_location_external_id(
        scope,
        tournament_overrides[:location_id],
        tournament_data["location"]
      )

      # Delete existing standings if re-importing
      if not is_new do
        Tournaments.delete_standings_by_tournament_id(scope, tournament.id)
      end

      # Create standings
      standings_count = create_standings(tournament, player_mappings, player_id_map)

      # Recalculate rankings if tournament is assigned to a season
      if tournament.season_id do
        Leagues.recalculate_season_rankings(scope, tournament.season_id)
      end

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

  defp build_players_map(players) do
    Enum.reduce(players, %{}, fn player, acc ->
      player_id = player["playerId"]
      Map.put(acc, player_id, player)
    end)
  end

  defp analyze_player_mappings(standings, players_map) do
    Enum.map(standings, fn standing ->
      player_id = standing["playerId"]
      position = standing["position"]

      # Get player data from the tournament players list
      player_data = Map.get(players_map, player_id, %{})

      # Prefer claimedBy (global userId) over playerId for external_id
      # claimedBy is the user's global Matchplay account ID
      matchplay_id = player_data["claimedBy"] || player_id
      external_id = "matchplay:#{matchplay_id}"

      # Get name from player data (not in standings response)
      name = player_data["name"] || ""

      # Try to find existing player by external_id
      case Players.get_player_by_external_id(nil, external_id) do
        %Player{} = player ->
          %{
            matchplay_player_id: matchplay_id,
            matchplay_name: name,
            position: position,
            qualifying_position: position,
            finals_position: nil,
            is_finalist: false,
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
            qualifying_position: position,
            finals_position: nil,
            is_finalist: false,
            match_type: match_type,
            local_player_id: nil,
            local_player: nil,
            suggested_players: suggested
          }
      end
    end)
  end

  # Merge qualifying and finals standings
  # Finals players get positions 1-N, non-finalists get (N+1) and beyond
  defp merge_standings(
         qualifying_standings,
         finals_standings,
         qualifying_players_map,
         finals_players_map
       ) do
    # Build lookup from claimedBy (or name fallback) to qualifying standing
    qualifying_lookup =
      Enum.reduce(qualifying_standings, %{}, fn standing, acc ->
        player_id = standing["playerId"]
        player_data = Map.get(qualifying_players_map, player_id, %{})
        claimed_by = player_data["claimedBy"]
        name = player_data["name"] || ""

        # Use claimedBy as primary key, name as fallback
        acc =
          if claimed_by do
            Map.put(acc, {:claimed_by, claimed_by}, {standing, player_data})
          else
            acc
          end

        if name != "" do
          Map.put(acc, {:name, name}, {standing, player_data})
        else
          acc
        end
      end)

    # Check that all finals players exist in qualifying
    unmatched_finals_players =
      Enum.reduce(finals_standings, [], fn standing, acc ->
        player_id = standing["playerId"]
        player_data = Map.get(finals_players_map, player_id, %{})
        claimed_by = player_data["claimedBy"]
        name = player_data["name"] || ""

        found =
          (claimed_by && Map.has_key?(qualifying_lookup, {:claimed_by, claimed_by})) ||
            (name != "" && Map.has_key?(qualifying_lookup, {:name, name}))

        if found, do: acc, else: [name | acc]
      end)

    if unmatched_finals_players != [] do
      {:error, {:finals_players_not_in_qualifying, Enum.reverse(unmatched_finals_players)}}
    else
      # Get set of finalist claimedBy IDs and names
      finalist_ids =
        Enum.reduce(finals_standings, MapSet.new(), fn standing, acc ->
          player_id = standing["playerId"]
          player_data = Map.get(finals_players_map, player_id, %{})
          claimed_by = player_data["claimedBy"]
          name = player_data["name"] || ""

          acc = if claimed_by, do: MapSet.put(acc, {:claimed_by, claimed_by}), else: acc
          if name != "", do: MapSet.put(acc, {:name, name}), else: acc
        end)

      finalist_count = length(finals_standings)

      # Build merged standings for finalists (positions 1 to N)
      finalists_merged =
        Enum.map(finals_standings, fn finals_standing ->
          finals_position = finals_standing["position"]
          player_id = finals_standing["playerId"]
          finals_player_data = Map.get(finals_players_map, player_id, %{})
          claimed_by = finals_player_data["claimedBy"]
          name = finals_player_data["name"] || ""

          # Find matching qualifying standing
          {qualifying_standing, qualifying_player_data} =
            cond do
              claimed_by && Map.has_key?(qualifying_lookup, {:claimed_by, claimed_by}) ->
                Map.get(qualifying_lookup, {:claimed_by, claimed_by})

              name != "" && Map.has_key?(qualifying_lookup, {:name, name}) ->
                Map.get(qualifying_lookup, {:name, name})
            end

          qualifying_position = qualifying_standing["position"]

          # Prefer qualifying player data (has the matchplay account linkage)
          matchplay_id = qualifying_player_data["claimedBy"] || qualifying_standing["playerId"]

          %{
            matchplay_player_id: matchplay_id,
            matchplay_name: qualifying_player_data["name"] || name,
            position: finals_position,
            qualifying_position: qualifying_position,
            finals_position: finals_position,
            is_finalist: true
          }
        end)

      # Build merged standings for non-finalists (positions N+1 onwards)
      non_finalists =
        qualifying_standings
        |> Enum.reject(fn standing ->
          player_id = standing["playerId"]
          player_data = Map.get(qualifying_players_map, player_id, %{})
          claimed_by = player_data["claimedBy"]
          name = player_data["name"] || ""

          MapSet.member?(finalist_ids, {:claimed_by, claimed_by}) ||
            MapSet.member?(finalist_ids, {:name, name})
        end)
        |> Enum.sort_by(fn standing -> standing["position"] end)
        |> Enum.with_index(finalist_count + 1)
        |> Enum.map(fn {standing, new_position} ->
          player_id = standing["playerId"]
          player_data = Map.get(qualifying_players_map, player_id, %{})
          matchplay_id = player_data["claimedBy"] || player_id
          qualifying_position = standing["position"]

          %{
            matchplay_player_id: matchplay_id,
            matchplay_name: player_data["name"] || "",
            position: new_position,
            qualifying_position: qualifying_position,
            finals_position: nil,
            is_finalist: false
          }
        end)

      merged = finalists_merged ++ non_finalists
      {:ok, merged, finalist_count}
    end
  end

  # Analyze player mappings for combined tournament results
  # Takes merged standings with position info already computed
  defp analyze_player_mappings_with_finals_info(merged_standings) do
    Enum.map(merged_standings, fn standing ->
      matchplay_id = standing.matchplay_player_id
      external_id = "matchplay:#{matchplay_id}"

      case Players.get_player_by_external_id(nil, external_id) do
        %Player{} = player ->
          Map.merge(standing, %{
            match_type: :auto,
            local_player_id: player.id,
            local_player: player,
            suggested_players: []
          })

        nil ->
          suggested = find_players_by_name(standing.matchplay_name)

          match_type =
            case suggested do
              [_single] -> :suggested
              _ -> :unmatched
            end

          Map.merge(standing, %{
            match_type: match_type,
            local_player_id: nil,
            local_player: nil,
            suggested_players: suggested
          })
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

  defp upsert_tournament(
         scope,
         external_id,
         finals_external_id,
         tournament_data,
         existing,
         overrides
       ) do
    # Build base attrs from API data
    base_attrs = %{
      external_id: external_id,
      finals_external_id: finals_external_id,
      external_url: tournament_data["link"],
      name: tournament_data["name"],
      start_at: parse_datetime(tournament_data["startUtc"])
    }

    # Merge user overrides, handling start_at specially if it's a string
    overrides = normalize_overrides(overrides)
    attrs = Map.merge(base_attrs, overrides)

    case existing do
      nil ->
        {:ok, tournament} = Tournaments.create_tournament(scope, attrs)
        tournament

      tournament ->
        {:ok, tournament} = Tournaments.update_tournament(scope, tournament, attrs)
        tournament
    end
  end

  defp normalize_overrides(overrides) when is_map(overrides) do
    overrides
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
    |> Enum.map(fn
      {:start_at, value} when is_binary(value) -> {:start_at, parse_datetime(value)}
      {key, value} -> {key, value}
    end)
    |> Map.new()
  end

  defp match_location_from_api(nil), do: {:ok, nil, false}

  defp match_location_from_api(location_data) do
    Locations.find_or_create_location_from_matchplay(nil, location_data)
  end

  defp maybe_update_location_external_id(_scope, nil, _location_data), do: :ok
  defp maybe_update_location_external_id(_scope, _location_id, nil), do: :ok

  defp maybe_update_location_external_id(scope, location_id, location_data) do
    matchplay_location_id = location_data["locationId"]

    if matchplay_location_id do
      location = Locations.get_location!(scope, location_id)

      if is_nil(location.external_id) or location.external_id == "" do
        external_id = "matchplay:#{matchplay_location_id}"
        {:ok, _} = Locations.update_location(scope, location, %{external_id: external_id})
      end
    end

    :ok
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    # Try ISO8601 format first (e.g., "2024-03-15T18:00:00Z")
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} ->
        DateTime.truncate(datetime, :second)

      {:error, _} ->
        # Try datetime-local format (e.g., "2024-03-15T18:00")
        parse_datetime_local(datetime_string)
    end
  end

  defp parse_datetime_local(datetime_string) do
    # Parse datetime-local format: YYYY-MM-DDTHH:MM (no seconds)
    # Append :00 for seconds if needed
    datetime_with_seconds =
      if String.match?(datetime_string, ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/) do
        datetime_string <> ":00"
      else
        datetime_string
      end

    case NaiveDateTime.from_iso8601(datetime_with_seconds) do
      {:ok, naive} ->
        DateTime.from_naive!(naive, "Etc/UTC")
        |> DateTime.truncate(:second)

      {:error, _} ->
        nil
    end
  end

  defp create_standings(tournament, player_mappings, player_id_map) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    player_count = length(player_mappings)
    meaningful_games = tournament.meaningful_games || 0

    # Pre-calculate all points
    points_by_position =
      if meaningful_games > 0 and player_count > 0 do
        TgpCalculator.calculate_all_points(player_count, meaningful_games)
        |> Map.new(&{&1.position, &1})
      else
        %{}
      end

    standings_attrs =
      Enum.map(player_mappings, fn mapping ->
        player_id = Map.fetch!(player_id_map, mapping.matchplay_player_id)
        points = Map.get(points_by_position, mapping.position, %{})

        %{
          tournament_id: tournament.id,
          player_id: player_id,
          position: mapping.position,
          is_finals: Map.get(mapping, :is_finalist, false),
          linear_points: points[:linear_points] || 0.0,
          dynamic_points: points[:dynamic_points] || 0.0,
          total_points: points[:total_points] || 0.0,
          inserted_at: now,
          updated_at: now
        }
      end)

    {count, _} = Repo.insert_all(Standing, standings_attrs)
    count
  end
end
