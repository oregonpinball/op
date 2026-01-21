defmodule OP.Leagues.Ranking do
  use Ecto.Schema
  import Ecto.Changeset

  alias OP.Leagues.Season
  alias OP.Players.Player

  schema "rankings" do
    field :is_rated, :boolean, default: false

    # Glicko
    field :rating, :float, default: 1500.0
    field :rating_deviation, :float, default: 200.0

    # Overall leaderboard data, e.g. position #1 - #100
    field :ranking, :integer

    # Aggregated season totals
    field :total_points, :float, default: 0.0
    field :event_count, :integer, default: 0

    belongs_to :player, Player
    belongs_to :season, Season

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ranking, attrs) do
    ranking
    |> cast(attrs, [
      :is_rated,
      :rating,
      :rating_deviation,
      :ranking,
      :total_points,
      :event_count,
      :player_id,
      :season_id
    ])
    |> validate_required([:player_id, :season_id])
    |> validate_number(:rating, greater_than_or_equal_to: 0)
    |> validate_number(:ranking, greater_than: 0)
    |> unique_constraint([:player_id, :season_id], name: :rankings_player_id_season_id_index)
  end
end
