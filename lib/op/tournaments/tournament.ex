defmodule OP.Tournaments.Tournament do
  use Ecto.Schema
  use OP.Sluggable

  import Ecto.Changeset

  alias OP.Accounts.User
  alias OP.Leagues.Season
  alias OP.Tournaments.Standing
  alias OP.Locations.Location

  schema "tournaments" do
    field :external_id, :string
    field :finals_external_id, :string
    field :external_url, :string

    field :name, :string
    field :slug, :string

    # HTML-formatted column to integrate with TipTap
    field :description, :string

    # Start of the tournament
    field :start_at, :utc_datetime

    field :qualifying_format, Ecto.Enum,
      values: [
        :single_elimination,
        :double_elimination,
        :match_play,
        :best_game,
        :card_qualifying,
        :pin_golf,
        :flip_frenzy,
        :strike_format,
        :target_match_play,
        :hybrid,
        :none
      ],
      default: :none

    field :finals_format, Ecto.Enum,
      values: [
        :single_elimination,
        :double_elimination,
        :strike_knockout_standard,
        :strike_knockout_fair,
        :strike_knockout_progressive,
        :group_match_play,
        :ladder,
        :amazing_race,
        :flip_frenzy,
        :target_match_play,
        :max_match_play,
        :none
      ],
      default: :none

    field :status, Ecto.Enum,
      values: [:draft, :pending_review, :sanctioned, :cancelled, :rejected],
      default: :draft

    field :meaningful_games, :float

    belongs_to :organizer, User
    belongs_to :season, Season
    belongs_to :location, Location
    belongs_to :created_by, User
    belongs_to :updated_by, User

    has_many :standings, Standing

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :external_id,
      :finals_external_id,
      :external_url,
      :name,
      :description,
      :start_at,
      :qualifying_format,
      :finals_format,
      :meaningful_games,
      :organizer_id,
      :season_id,
      :location_id,
      :status,
      :slug,
      :created_by_id,
      :updated_by_id
    ])
    |> generate_slug()
    |> cast_assoc(:standings,
      with: &Standing.form_changeset/2,
      sort_param: :standings_sort,
      drop_param: :standings_drop
    )
    |> validate_required([:name, :start_at])
    |> validate_number(:meaningful_games, greater_than_or_equal_to: 0.0)
  end
end
