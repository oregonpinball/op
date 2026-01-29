defmodule OP.Leagues.Season do
  use Ecto.Schema
  use OP.Sluggable
  import Ecto.Changeset

  alias OP.Leagues.{League, Ranking}

  schema "seasons" do
    field :name, :string
    # HTML-formatted column to integrate with TipTap
    field :description, :string

    # Publicly-usable URL slug for accessing the season
    # -> can be customized for vanity URLs, etc
    field :slug, :string

    # Start and end times the season is "open" for
    field :start_at, :utc_datetime
    field :end_at, :utc_datetime

    field :ranking_calculation_method, Ecto.Enum,
      values: [:oppr_v1_0],
      default: :oppr_v1_0

    belongs_to :league, League
    has_many :rankings, Ranking

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(season, attrs) do
    season
    |> cast(attrs, [
      :name,
      :description,
      :slug,
      :start_at,
      :end_at,
      :league_id,
      :ranking_calculation_method
    ])
    |> generate_slug()
    |> validate_required([:name, :league_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:slug, min: 2, max: 255)
    |> validate_dates()
    |> unique_constraint(:slug)
  end

  defp validate_dates(changeset) do
    start_at = get_field(changeset, :start_at)
    end_at = get_field(changeset, :end_at)

    if start_at && end_at && DateTime.compare(start_at, end_at) != :lt do
      add_error(changeset, :end_at, "must be after start date")
    else
      changeset
    end
  end
end
