defmodule OP.Leagues do
  @moduledoc """
  The Leagues context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Leagues.{League, Ranking, RankingCalculator, Season}

  # League functions

  @doc """
  Returns the list of leagues.

  ## Examples

      iex> list_leagues(current_scope)
      [%League{}, ...]

  """
  def list_leagues(_scope) do
    Repo.all(League)
  end

  @doc """
  Returns the list of leagues with preloaded associations.

  ## Examples

      iex> list_leagues_with_preloads(current_scope)
      [%League{}, ...]

  """
  def list_leagues_with_preloads(_scope) do
    League
    |> preload([:author, seasons: [rankings: :player]])
    |> Repo.all()
  end

  @doc """
  Returns the list of leagues created by the current user.

  ## Examples

      iex> list_my_leagues(current_scope)
      [%League{}, ...]

  """
  def list_my_leagues(_scope) do
    League
    |> order_by([l], desc: l.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single league.

  Raises `Ecto.NoResultsError` if the League does not exist.

  ## Examples

      iex> get_league!(current_scope, 123)
      %League{}

      iex> get_league!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_league!(_scope, id), do: Repo.get!(League, id)

  @doc """
  Gets a single league with preloaded associations.

  Raises `Ecto.NoResultsError` if the League does not exist.

  ## Examples

      iex> get_league_with_preloads!(current_scope, 123)
      %League{}

      iex> get_league_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_league_with_preloads!(_scope, id) do
    League
    |> preload([:author, :seasons])
    |> Repo.get!(id)
  end

  @doc """
  Gets a league by slug.

  ## Examples

      iex> get_league_by_slug(current_scope, "my-league")
      %League{}

      iex> get_league_by_slug(current_scope, "unknown")
      nil

  """
  def get_league_by_slug(_scope, slug) when is_binary(slug) do
    Repo.get_by(League, slug: slug)
  end

  @doc """
  Creates a league.

  ## Examples

      iex> create_league(current_scope, %{field: value})
      {:ok, %League{}}

      iex> create_league(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_league(_scope, attrs \\ %{}) do
    %League{}
    |> League.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a league.

  ## Examples

      iex> update_league(current_scope, league, %{field: new_value})
      {:ok, %League{}}

      iex> update_league(current_scope, league, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_league(_scope, %League{} = league, attrs) do
    league
    |> League.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a league.

  ## Examples

      iex> delete_league(current_scope, league)
      {:ok, %League{}}

      iex> delete_league(current_scope, league)
      {:error, %Ecto.Changeset{}}

  """
  def delete_league(_scope, %League{} = league) do
    Repo.delete(league)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking league changes.

  ## Examples

      iex> change_league(league)
      %Ecto.Changeset{data: %League{}}

  """
  def change_league(%League{} = league, attrs \\ %{}) do
    League.changeset(league, attrs)
  end

  # Season functions

  @doc """
  Returns the list of seasons.

  ## Examples

      iex> list_seasons(current_scope)
      [%Season{}, ...]

  """
  def list_seasons(_scope) do
    Repo.all(Season)
  end

  @doc """
  Returns the list of seasons with preloaded associations.

  ## Examples

      iex> list_seasons_with_preloads(current_scope)
      [%Season{}, ...]

  """
  def list_seasons_with_preloads(_scope) do
    Season
    |> preload([:league])
    |> Repo.all()
  end

  @doc """
  Returns the list of seasons filtered by league.

  ## Examples

      iex> list_seasons_by_league(current_scope, league_id)
      [%Season{}, ...]

  """
  def list_seasons_by_league(_scope, league_id) do
    Season
    |> where([s], s.league_id == ^league_id)
    |> order_by([s], desc: s.start_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of active seasons (currently running).

  ## Examples

      iex> list_active_seasons(current_scope)
      [%Season{}, ...]

  """
  def list_active_seasons(_scope) do
    now = DateTime.utc_now()

    Season
    |> where([s], s.start_at <= ^now and s.end_at >= ^now)
    |> order_by([s], asc: s.start_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of upcoming seasons.

  ## Examples

      iex> list_upcoming_seasons(current_scope)
      [%Season{}, ...]

  """
  def list_upcoming_seasons(_scope) do
    now = DateTime.utc_now()

    Season
    |> where([s], s.start_at > ^now)
    |> order_by([s], asc: s.start_at)
    |> Repo.all()
  end

  @doc """
  Gets a single season.

  Raises `Ecto.NoResultsError` if the Season does not exist.

  ## Examples

      iex> get_season!(current_scope, 123)
      %Season{}

      iex> get_season!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_season!(_scope, id), do: Repo.get!(Season, id)

  @doc """
  Gets a single season with preloaded associations.

  Raises `Ecto.NoResultsError` if the Season does not exist.

  ## Examples

      iex> get_season_with_preloads!(current_scope, 123)
      %Season{}

      iex> get_season_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_season_with_preloads!(_scope, id) do
    Season
    |> preload([:league])
    |> Repo.get!(id)
  end

  @doc """
  Gets a season by slug.

  ## Examples

      iex> get_season_by_slug(current_scope, "season-1")
      %Season{}

      iex> get_season_by_slug(current_scope, "unknown")
      nil

  """
  def get_season_by_slug(_scope, slug) when is_binary(slug) do
    Season
    |> Repo.get_by(slug: slug)
    |> Repo.preload(:league)
  end

  @doc """
  Creates a season.

  ## Examples

      iex> create_season(current_scope, %{field: value})
      {:ok, %Season{}}

      iex> create_season(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_season(_scope, attrs \\ %{}) do
    %Season{}
    |> Season.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a season.

  ## Examples

      iex> update_season(current_scope, season, %{field: new_value})
      {:ok, %Season{}}

      iex> update_season(current_scope, season, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_season(_scope, %Season{} = season, attrs) do
    season
    |> Season.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a season.

  ## Examples

      iex> delete_season(current_scope, season)
      {:ok, %Season{}}

      iex> delete_season(current_scope, season)
      {:error, %Ecto.Changeset{}}

  """
  def delete_season(_scope, %Season{} = season) do
    Repo.delete(season)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking season changes.

  ## Examples

      iex> change_season(season)
      %Ecto.Changeset{data: %Season{}}

  """
  def change_season(%Season{} = season, attrs \\ %{}) do
    Season.changeset(season, attrs)
  end

  # Ranking functions

  @doc """
  Recalculates rankings for a season by aggregating total_points from tournament standings.

  Returns `{:ok, count}` with the number of rankings upserted, or `{:error, reason}` on failure.

  ## Examples

      iex> recalculate_season_rankings(current_scope, season_id)
      {:ok, 42}

  """
  def recalculate_season_rankings(_scope, season_id) do
    RankingCalculator.recalculate_season_rankings(season_id)
  end

  @doc """
  Returns the list of rankings for a season, ordered by ranking position.

  ## Examples

      iex> list_rankings_by_season(current_scope, season_id)
      [%Ranking{}, ...]

  """
  def list_rankings_by_season(_scope, season_id) do
    Ranking
    |> where([r], r.season_id == ^season_id)
    |> order_by([r], asc: r.ranking)
    |> preload(:player)
    |> Repo.all()
  end

  @doc """
  Gets a player's ranking for a specific season.

  Returns nil if the player has no ranking for that season.

  ## Examples

      iex> get_player_ranking(current_scope, player_id, season_id)
      %Ranking{}

      iex> get_player_ranking(current_scope, unknown_player_id, season_id)
      nil

  """
  def get_player_ranking(_scope, player_id, season_id) do
    Ranking
    |> where([r], r.player_id == ^player_id and r.season_id == ^season_id)
    |> preload(:player)
    |> Repo.one()
  end

  @doc """
  Returns the list of rankings for a season with sorting support.

  ## Options

    * `:sort_by` - Column to sort by: "ranking", "points", or "name". Defaults to "ranking".
    * `:sort_dir` - Sort direction: "asc" or "desc". Defaults to "asc".

  ## Examples

      iex> list_rankings_by_season_sorted(current_scope, season_id)
      [%Ranking{}, ...]

      iex> list_rankings_by_season_sorted(current_scope, season_id, sort_by: "points", sort_dir: "desc")
      [%Ranking{}, ...]

  """
  def list_rankings_by_season_sorted(_scope, season_id, opts \\ []) do
    sort_by = Keyword.get(opts, :sort_by, "ranking")
    sort_dir = Keyword.get(opts, :sort_dir, "asc")

    direction = if sort_dir == "desc", do: :desc, else: :asc

    Ranking
    |> where([r], r.season_id == ^season_id)
    |> preload(:player)
    |> apply_ranking_sort(sort_by, direction)
    |> Repo.all()
  end

  defp apply_ranking_sort(query, "ranking", dir) do
    order_by(query, [r], [{^dir, r.ranking}])
  end

  defp apply_ranking_sort(query, "points", dir) do
    order_by(query, [r], [{^dir, r.total_points}])
  end

  defp apply_ranking_sort(query, "name", dir) do
    from r in query,
      join: p in assoc(r, :player),
      order_by: [{^dir, p.name}]
  end

  defp apply_ranking_sort(query, _default, dir) do
    order_by(query, [r], [{^dir, r.ranking}])
  end

  @doc """
  Returns the list of rankings for a player, ordered by ranking position.

  Preloads season and its league.

  ## Examples

      iex> list_rankings_by_player(current_scope, player_id)
      [%Ranking{}, ...]

  """
  def list_rankings_by_player(_scope, player_id) do
    Ranking
    |> where([r], r.player_id == ^player_id)
    |> order_by([r], asc: r.ranking)
    |> preload(season: :league)
    |> Repo.all()
  end
end
