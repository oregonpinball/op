defmodule OP.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Tournaments.Tournament

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments(current_scope)
      [%Tournament{}, ...]

  """
  def list_tournaments(_scope) do
    Repo.all(Tournament)
  end

  @doc """
  Returns the list of tournaments with preloaded associations.

  ## Examples

      iex> list_tournaments_with_preloads(current_scope)
      [%Tournament{}, ...]

  """
  def list_tournaments_with_preloads(_scope) do
    Tournament
    |> preload([:organizer, :season, :location, :standings])
    |> Repo.all()
  end

  @doc """
  Returns a paginated list of tournaments with optional search and filters.

  ## Options

    * `:page` - Current page number (default: 1)
    * `:per_page` - Items per page (default: 25)
    * `:search` - Tournament name search string
    * `:location_id` - Filter by location ID
    * `:start_date` - Filter tournaments starting on or after this date
    * `:end_date` - Filter tournaments starting on or before this date

  ## Returns

    A tuple `{tournaments, pagination_meta}` where pagination_meta contains:
    * `:page` - Current page
    * `:per_page` - Items per page
    * `:total_count` - Total number of matching tournaments
    * `:total_pages` - Total number of pages

  ## Examples

      iex> list_tournaments_paginated(current_scope, page: 1, search: "open")
      {[%Tournament{}, ...], %{page: 1, per_page: 25, total_count: 50, total_pages: 2}}

  """
  def list_tournaments_paginated(_scope, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 25)
    search = Keyword.get(opts, :search)
    location_id = Keyword.get(opts, :location_id)
    start_date = Keyword.get(opts, :start_date)
    end_date = Keyword.get(opts, :end_date)

    base_query =
      Tournament
      |> preload([:organizer, :season, :location, :standings])
      |> order_by([t], desc: t.start_at)

    filtered_query =
      base_query
      |> filter_by_search(search)
      |> filter_by_location(location_id)
      |> filter_by_date_range(start_date, end_date)

    total_count = Repo.aggregate(filtered_query, :count, :id)
    total_pages = ceil(total_count / per_page)

    tournaments =
      filtered_query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> Repo.all()

    pagination_meta = %{
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: max(total_pages, 1)
    }

    {tournaments, pagination_meta}
  end

  defp filter_by_search(query, nil), do: query
  defp filter_by_search(query, ""), do: query

  defp filter_by_search(query, search) do
    search_term = "%#{search}%"
    where(query, [t], ilike(t.name, ^search_term))
  end

  defp filter_by_location(query, nil), do: query
  defp filter_by_location(query, ""), do: query

  defp filter_by_location(query, location_id) do
    where(query, [t], t.location_id == ^location_id)
  end

  defp filter_by_date_range(query, nil, nil), do: query

  defp filter_by_date_range(query, start_date, nil) when not is_nil(start_date) do
    case date_to_datetime(start_date, :start) do
      nil -> query
      start_datetime -> where(query, [t], t.start_at >= ^start_datetime)
    end
  end

  defp filter_by_date_range(query, nil, end_date) when not is_nil(end_date) do
    case date_to_datetime(end_date, :end) do
      nil -> query
      end_datetime -> where(query, [t], t.start_at <= ^end_datetime)
    end
  end

  defp filter_by_date_range(query, start_date, end_date) do
    start_datetime = date_to_datetime(start_date, :start)
    end_datetime = date_to_datetime(end_date, :end)

    cond do
      is_nil(start_datetime) and is_nil(end_datetime) -> query
      is_nil(start_datetime) -> where(query, [t], t.start_at <= ^end_datetime)
      is_nil(end_datetime) -> where(query, [t], t.start_at >= ^start_datetime)
      true -> where(query, [t], t.start_at >= ^start_datetime and t.start_at <= ^end_datetime)
    end
  end

  defp date_to_datetime(date_string, :start) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
      _ -> nil
    end
  end

  defp date_to_datetime(date_string, :end) when is_binary(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
      _ -> nil
    end
  end

  defp date_to_datetime(nil, _), do: nil
  defp date_to_datetime(_, _), do: nil

  @doc """
  Returns the list of tournaments filtered by season.

  ## Examples

      iex> list_tournaments_by_season(current_scope, season_id)
      [%Tournament{}, ...]

  """
  def list_tournaments_by_season(_scope, season_id) do
    Tournament
    |> where([t], t.season_id == ^season_id)
    |> order_by([t], desc: t.start_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of tournaments organized by the current user.

  ## Examples

      iex> list_my_tournaments(current_scope)
      [%Tournament{}, ...]

  """
  def list_my_tournaments(_scope) do
    Tournament
    |> order_by([t], desc: t.start_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of upcoming tournaments.

  ## Examples

      iex> list_upcoming_tournaments(current_scope)
      [%Tournament{}, ...]

  """
  def list_upcoming_tournaments(_scope) do
    now = DateTime.utc_now()

    Tournament
    |> where([t], t.start_at >= ^now)
    |> order_by([t], asc: t.start_at)
    |> Repo.all()
  end

  @doc """
  Returns the list of past tournaments.

  ## Examples

      iex> list_past_tournaments(current_scope)
      [%Tournament{}, ...]

  """
  def list_past_tournaments(_scope) do
    now = DateTime.utc_now()

    Tournament
    |> where([t], t.start_at < ^now)
    |> order_by([t], desc: t.start_at)
    |> Repo.all()
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament!(current_scope, 123)
      %Tournament{}

      iex> get_tournament!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament!(_scope, id), do: Repo.get!(Tournament, id)

  @doc """
  Gets a single tournament with preloaded associations.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament_with_preloads!(current_scope, 123)
      %Tournament{}

      iex> get_tournament_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament_with_preloads!(_scope, id) do
    Tournament
    |> preload([:organizer, :season, :location, standings: :player])
    |> Repo.get!(id)
  end

  @doc """
  Gets a tournament by external_id.

  ## Examples

      iex> get_tournament_by_external_id(current_scope, "ext_123")
      %Tournament{}

      iex> get_tournament_by_external_id(current_scope, "unknown")
      nil

  """
  def get_tournament_by_external_id(_scope, external_id) when is_binary(external_id) do
    Repo.get_by(Tournament, external_id: external_id)
  end

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(current_scope, %{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(_scope, attrs \\ %{}) do
    %Tournament{}
    |> Tournament.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(current_scope, tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(current_scope, tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(_scope, %Tournament{} = tournament, attrs) do
    tournament
    |> Tournament.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(current_scope, tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(current_scope, tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(_scope, %Tournament{} = tournament) do
    Repo.delete(tournament)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(current_scope, tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(_scope, %Tournament{} = tournament, attrs \\ %{}) do
    Tournament.changeset(tournament, attrs)
  end

  alias OP.Tournaments.Standing

  @doc """
  Deletes all standings for a given tournament.

  Used when re-importing a tournament to replace existing standings.

  ## Examples

      iex> delete_standings_by_tournament_id(current_scope, tournament_id)
      {5, nil}

  """
  def delete_standings_by_tournament_id(_scope, tournament_id) do
    Standing
    |> where([s], s.tournament_id == ^tournament_id)
    |> Repo.delete_all()
  end
end
