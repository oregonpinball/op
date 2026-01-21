defmodule OP.Tournaments.Standing do
  use Ecto.Schema
  import Ecto.Changeset

  alias OP.Players.Player
  alias OP.Tournaments.Tournament

  schema "standings" do
    field :position, :integer

    field :is_finals, :boolean, default: false

    field :linear_points, :float, default: 0.0
    field :dynamic_points, :float, default: 0.0
    field :age_in_days, :integer, default: 0
    field :decay_multiplier, :float, default: 1.0
    field :total_points, :float
    field :decayed_points, :float
    field :efficiency, :float

    belongs_to :tournament, Tournament
    belongs_to :player, Player

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(standing, attrs) do
    standing
    |> cast(attrs, [
      :position,
      :is_finals,
      :linear_points,
      :dynamic_points,
      :age_in_days,
      :decay_multiplier,
      :total_points,
      :decayed_points,
      :efficiency,
      :tournament_id,
      :player_id
    ])
    |> validate_required([:tournament_id, :player_id])
    |> validate_number(:position, greater_than_or_equal_to: 1)
    |> validate_number(:linear_points, greater_than_or_equal_to: 0.0)
    |> validate_number(:dynamic_points, greater_than_or_equal_to: 0.0)
    |> validate_number(:age_in_days, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for nested form usage. Does not require tournament_id since it will
  be set by the parent association.
  """
  def form_changeset(standing, attrs) do
    standing
    |> cast(attrs, [
      :position,
      :is_finals,
      :player_id
    ])
    |> validate_required([:position, :player_id])
    |> validate_number(:position, greater_than_or_equal_to: 1)
  end
end
