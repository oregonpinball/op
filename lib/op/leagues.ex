defmodule OP.Leagues do
  @moduledoc """
  The Leagues context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Accounts.Scope
  alias OP.Leagues.{League, Season}

  # League functions

  @doc """
  Returns the list of leagues.

  ## Examples

      iex> list_leagues(current_scope)
      [%League{}, ...]

  """
  def list_leagues(%Scope{} = _current_scope) do
    Repo.all(League)
  end

  # Fall back for when `scope` is `nil` for public access
  def list_leagues(_) do
    Repo.all(League)
  end

  @doc """
  Returns the list of leagues with preloaded associations.

  ## Examples

      iex> list_leagues_with_preloads(current_scope)
      [%League{}, ...]

  """
  def list_leagues_with_preloads(%Scope{} = _current_scope) do
    League
    |> preload([:author])
    |> Repo.all()
  end

  # Fall back for when `scope` is `nil` for public access
  def list_leagues_with_preloads(_) do
    League
    |> preload([:author])
    |> Repo.all()
  end

  @doc """
  Returns the list of leagues created by the current user.

  ## Examples

      iex> list_my_leagues(current_scope)
      [%League{}, ...]

  """
  def list_my_leagues(%Scope{user: %{id: user_id}}) do
    League
    |> where([l], l.author_id == ^user_id)
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
  def get_league!(%Scope{} = _current_scope, id), do: Repo.get!(League, id)

  # Fall back for when `scope` is `nil` for public access
  def get_league!(_, id), do: Repo.get!(League, id)

  @doc """
  Gets a single league with preloaded associations.

  Raises `Ecto.NoResultsError` if the League does not exist.

  ## Examples

      iex> get_league_with_preloads!(current_scope, 123)
      %League{}

      iex> get_league_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_league_with_preloads!(%Scope{} = _current_scope, id) do
    League
    |> preload([:author])
    |> Repo.get!(id)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_league_with_preloads!(_, id) do
    League
    |> preload([:author])
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
  def get_league_by_slug(%Scope{} = _current_scope, slug) when is_binary(slug) do
    Repo.get_by(League, slug: slug)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_league_by_slug(_, slug) when is_binary(slug) do
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
  def create_league(scope, attrs \\ %{})

  def create_league(%Scope{} = _current_scope, attrs) do
    %League{}
    |> League.changeset(attrs)
    |> Repo.insert()
  end

  # Fall back for when `scope` is `nil` for public access
  def create_league(_, attrs) do
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
  def update_league(%Scope{} = _current_scope, %League{} = league, attrs) do
    league
    |> League.changeset(attrs)
    |> Repo.update()
  end

  # Fall back for when `scope` is `nil` for public access
  def update_league(_, %League{} = league, attrs) do
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
  def delete_league(%Scope{} = _current_scope, %League{} = league) do
    Repo.delete(league)
  end

  # Fall back for when `scope` is `nil` for public access
  def delete_league(_, %League{} = league) do
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
  def list_seasons(%Scope{} = _current_scope) do
    Repo.all(Season)
  end

  # Fall back for when `scope` is `nil` for public access
  def list_seasons(_) do
    Repo.all(Season)
  end

  @doc """
  Returns the list of seasons with preloaded associations.

  ## Examples

      iex> list_seasons_with_preloads(current_scope)
      [%Season{}, ...]

  """
  def list_seasons_with_preloads(%Scope{} = _current_scope) do
    Season
    |> preload([:league])
    |> Repo.all()
  end

  # Fall back for when `scope` is `nil` for public access
  def list_seasons_with_preloads(_) do
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
  def list_seasons_by_league(%Scope{} = _current_scope, league_id) do
    Season
    |> where([s], s.league_id == ^league_id)
    |> order_by([s], desc: s.start_at)
    |> Repo.all()
  end

  # Fall back for when `scope` is `nil` for public access
  def list_seasons_by_league(_, league_id) do
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
  def list_active_seasons(%Scope{} = _current_scope) do
    now = DateTime.utc_now()

    Season
    |> where([s], s.start_at <= ^now and s.end_at >= ^now)
    |> order_by([s], asc: s.start_at)
    |> Repo.all()
  end

  # Fall back for when `scope` is `nil` for public access
  def list_active_seasons(_) do
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
  def list_upcoming_seasons(%Scope{} = _current_scope) do
    now = DateTime.utc_now()

    Season
    |> where([s], s.start_at > ^now)
    |> order_by([s], asc: s.start_at)
    |> Repo.all()
  end

  # Fall back for when `scope` is `nil` for public access
  def list_upcoming_seasons(_) do
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
  def get_season!(%Scope{} = _current_scope, id), do: Repo.get!(Season, id)

  # Fall back for when `scope` is `nil` for public access
  def get_season!(_, id), do: Repo.get!(Season, id)

  @doc """
  Gets a single season with preloaded associations.

  Raises `Ecto.NoResultsError` if the Season does not exist.

  ## Examples

      iex> get_season_with_preloads!(current_scope, 123)
      %Season{}

      iex> get_season_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_season_with_preloads!(%Scope{} = _current_scope, id) do
    Season
    |> preload([:league])
    |> Repo.get!(id)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_season_with_preloads!(_, id) do
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
  def get_season_by_slug(%Scope{} = _current_scope, slug) when is_binary(slug) do
    Repo.get_by(Season, slug: slug)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_season_by_slug(_, slug) when is_binary(slug) do
    Repo.get_by(Season, slug: slug)
  end

  @doc """
  Creates a season.

  ## Examples

      iex> create_season(current_scope, %{field: value})
      {:ok, %Season{}}

      iex> create_season(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_season(scope, attrs \\ %{})

  def create_season(%Scope{} = _current_scope, attrs) do
    %Season{}
    |> Season.changeset(attrs)
    |> Repo.insert()
  end

  # Fall back for when `scope` is `nil` for public access
  def create_season(_, attrs) do
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
  def update_season(%Scope{} = _current_scope, %Season{} = season, attrs) do
    season
    |> Season.changeset(attrs)
    |> Repo.update()
  end

  # Fall back for when `scope` is `nil` for public access
  def update_season(_, %Season{} = season, attrs) do
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
  def delete_season(%Scope{} = _current_scope, %Season{} = season) do
    Repo.delete(season)
  end

  # Fall back for when `scope` is `nil` for public access
  def delete_season(_, %Season{} = season) do
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
end
