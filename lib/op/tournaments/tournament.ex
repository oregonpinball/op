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
    field :external_url, :string

    field :name, :string
    field :slug, :string

    # HTML-formatted column to integrate with TipTap
    field :description, :string

    # Start and estimated end of the tournament
    field :start_at, :utc_datetime
    field :end_at, :utc_datetime

    field :tgp_config, :map

    field :event_booster, Ecto.Enum,
      values: [:none, :certified, :certified_plus, :championship_series, :major],
      default: :none

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

    field :allows_opt_out, :boolean, default: false

    field :base_value, :float
    field :tva_rating, :float
    field :tva_ranking, :float
    field :total_tva, :float
    field :tgp, :float
    field :event_booster_multiplier, :float
    field :first_place_value, :float

    belongs_to :organizer, User
    belongs_to :season, Season
    belongs_to :location, Location

    has_many :standings, Standing

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :external_id,
      :external_url,
      :name,
      :description,
      :start_at,
      :end_at,
      :tgp_config,
      :event_booster,
      :qualifying_format,
      :allows_opt_out,
      :base_value,
      :tva_rating,
      :tva_ranking,
      :total_tva,
      :tgp,
      :event_booster_multiplier,
      :first_place_value,
      :organizer_id,
      :season_id,
      :location_id,
      :slug
    ])
    |> generate_slug()
    |> cast_assoc(:standings,
      with: &Standing.form_changeset/2,
      sort_param: :standings_sort,
      drop_param: :standings_drop
    )
    |> validate_required([:name, :start_at])
    |> validate_number(:base_value, greater_than_or_equal_to: 0.0)
    |> validate_number(:tva_rating, greater_than_or_equal_to: 0.0)
    |> validate_number(:tva_ranking, greater_than_or_equal_to: 0.0)
    |> validate_number(:total_tva, greater_than_or_equal_to: 0.0)
    |> validate_number(:tgp, greater_than_or_equal_to: 0.0)
    |> validate_number(:first_place_value, greater_than_or_equal_to: 0.0)
  end
end
