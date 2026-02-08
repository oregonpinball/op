defmodule OP.Tournaments.Tournament do
  use Ecto.Schema
  use OP.Sluggable

  import Ecto.Changeset

  alias OP.Accounts.User
  alias OP.Leagues.Season
  alias OP.Tournaments.Standing
  alias OP.Locations.Location

  @matchplay_base_url "https://app.matchplay.events/tournaments"

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

    field :qualifying_matchplay_url, :string, virtual: true
    field :finals_matchplay_url, :string, virtual: true

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
    |> cast(attrs, [:qualifying_matchplay_url, :finals_matchplay_url], empty_values: [])
    |> process_matchplay_urls()
    |> generate_slug()
    |> cast_assoc(:standings,
      with: &Standing.form_changeset/2,
      sort_param: :standings_sort,
      drop_param: :standings_drop
    )
    |> validate_required([:name, :start_at])
    |> validate_number(:meaningful_games, greater_than_or_equal_to: 0.0)
  end

  @doc """
  Reconstructs a full Matchplay URL from a stored external_id like "matchplay:12345".
  Returns nil if the external_id is nil or doesn't match the expected format.
  """
  def matchplay_url_from_external_id(nil), do: nil

  def matchplay_url_from_external_id("matchplay:" <> id) do
    "#{@matchplay_base_url}/#{id}"
  end

  def matchplay_url_from_external_id(_), do: nil

  defp process_matchplay_urls(changeset) do
    changeset
    |> process_qualifying_url()
    |> process_finals_url()
  end

  defp process_qualifying_url(changeset) do
    case get_change(changeset, :qualifying_matchplay_url) do
      nil ->
        changeset

      "" ->
        changeset
        |> put_change(:external_id, nil)
        |> put_change(:external_url, nil)

      url_or_id ->
        case extract_matchplay_id(url_or_id) do
          {:ok, id} ->
            changeset
            |> put_change(:external_id, "matchplay:#{id}")
            |> put_change(:external_url, "#{@matchplay_base_url}/#{id}")

          :error ->
            add_error(
              changeset,
              :qualifying_matchplay_url,
              "must be a valid Matchplay URL or numeric ID"
            )
        end
    end
  end

  defp process_finals_url(changeset) do
    case get_change(changeset, :finals_matchplay_url) do
      nil ->
        changeset

      "" ->
        changeset
        |> put_change(:finals_external_id, nil)

      url_or_id ->
        case extract_matchplay_id(url_or_id) do
          {:ok, id} ->
            changeset
            |> put_change(:finals_external_id, "matchplay:#{id}")

          :error ->
            add_error(
              changeset,
              :finals_matchplay_url,
              "must be a valid Matchplay URL or numeric ID"
            )
        end
    end
  end

  defp extract_matchplay_id(input) do
    input = String.trim(input)

    cond do
      Regex.match?(~r/^\d+$/, input) ->
        {:ok, input}

      match = Regex.run(~r/tournaments\/(\d+)/, input) ->
        {:ok, Enum.at(match, 1)}

      true ->
        :error
    end
  end
end
