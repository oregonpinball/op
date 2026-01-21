defmodule OP.Leagues.RankingCalculator do
  @moduledoc """
  Calculates and updates league season rankings by aggregating tournament standings.

  Rankings are based on total_points (not decayed_points) from tournament standings
  within each season.
  """

  import Ecto.Query, warn: false

  alias OP.Leagues.Ranking
  alias OP.Repo
  alias OP.Tournaments.Standing
  alias OP.Tournaments.Tournament

  @doc """
  Recalculates rankings for a season by aggregating total_points from tournament standings.

  Returns `{:ok, count}` with the number of rankings upserted, or `{:error, reason}` on failure.
  """
  @spec recalculate_season_rankings(integer()) :: {:ok, non_neg_integer()} | {:error, term()}
  def recalculate_season_rankings(season_id) when is_integer(season_id) do
    aggregated = aggregate_season_standings(season_id)

    if Enum.empty?(aggregated) do
      {:ok, 0}
    else
      upsert_rankings(season_id, aggregated)
    end
  end

  @doc """
  Aggregates standings for a season, returning a list of maps with player_id, total_points, and event_count.

  Results are ordered by total_points descending.
  """
  @spec aggregate_season_standings(integer()) :: [
          %{player_id: integer(), total_points: float(), event_count: integer()}
        ]
  def aggregate_season_standings(season_id) do
    from(s in Standing,
      join: t in Tournament,
      on: s.tournament_id == t.id,
      where: t.season_id == ^season_id,
      group_by: s.player_id,
      select: %{
        player_id: s.player_id,
        total_points: sum(s.total_points),
        event_count: count(s.id)
      },
      order_by: [desc: sum(s.total_points)]
    )
    |> Repo.all()
  end

  defp upsert_rankings(season_id, aggregated) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Assign rankings (1-indexed position based on sorted order)
    rankings_data =
      aggregated
      |> Enum.with_index(1)
      |> Enum.map(fn {data, rank} ->
        %{
          season_id: season_id,
          player_id: data.player_id,
          total_points: data.total_points || 0.0,
          event_count: data.event_count,
          ranking: rank,
          inserted_at: now,
          updated_at: now
        }
      end)

    {count, _} =
      Repo.insert_all(
        Ranking,
        rankings_data,
        on_conflict: {:replace, [:total_points, :event_count, :ranking, :updated_at]},
        conflict_target: [:player_id, :season_id]
      )

    {:ok, count}
  end
end
