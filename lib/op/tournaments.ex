defmodule OP.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias OP.Leagues
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
    season_id = Keyword.get(opts, :season_id)
    league_id = Keyword.get(opts, :league_id)
    status = Keyword.get(opts, :status)

    sort_by = Keyword.get(opts, :sort_by, :start_at)
    sort_dir = Keyword.get(opts, :sort_dir, :desc)

    base_query =
      Tournament
      |> preload([:organizer, [season: :league], :location, :standings])
      |> apply_sort(sort_by, sort_dir)

    filtered_query =
      base_query
      |> filter_by_search(search)
      |> filter_by_location(location_id)
      |> filter_by_date_range(start_date, end_date)
      |> filter_by_season(season_id)
      |> filter_by_league(league_id)
      |> filter_by_status(status)

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
    search_term = "%#{String.downcase(search)}%"
    where(query, [t], like(fragment("lower(?)", t.name), ^search_term))
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

  defp filter_by_season(query, nil), do: query
  defp filter_by_season(query, ""), do: query

  defp filter_by_season(query, season_id) do
    where(query, [t], t.season_id == ^season_id)
  end

  defp filter_by_league(query, nil), do: query
  defp filter_by_league(query, ""), do: query

  defp filter_by_league(query, league_id) do
    from t in query,
      join: s in assoc(t, :season),
      where: s.league_id == ^league_id
  end

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, ""), do: query
  defp filter_by_status(query, "all"), do: query

  defp filter_by_status(query, "upcoming") do
    now = DateTime.utc_now()
    where(query, [t], t.start_at >= ^now)
  end

  defp filter_by_status(query, "past") do
    now = DateTime.utc_now()
    where(query, [t], t.start_at < ^now)
  end

  @allowed_sort_fields ~w(name start_at status)a

  defp apply_sort(query, sort_by, sort_dir)
       when sort_by in @allowed_sort_fields and sort_dir in [:asc, :desc] do
    order_by(query, [t], [{^sort_dir, field(t, ^sort_by)}])
  end

  defp apply_sort(query, :location, sort_dir) when sort_dir in [:asc, :desc] do
    from t in query,
      left_join: l in assoc(t, :location),
      order_by: [{^sort_dir, l.name}]
  end

  defp apply_sort(query, :organizer, sort_dir) when sort_dir in [:asc, :desc] do
    from t in query,
      left_join: u in assoc(t, :organizer),
      order_by: [{^sort_dir, u.email}]
  end

  defp apply_sort(query, _sort_by, _sort_dir) do
    order_by(query, [t], desc: t.start_at)
  end

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
  Returns a paginated list of tournaments organized by the given user.
  Accepts the same filter/sort/pagination options as `list_tournaments_paginated/2`.
  """
  def list_organized_tournaments_paginated(scope, opts \\ []) do
    user_id = scope.user.id

    opts
    |> Keyword.put(:base_query_fn, fn ->
      Tournament
      |> where([t], t.organizer_id == ^user_id)
      |> preload([:organizer, [season: :league], :location, :standings])
    end)
    |> do_list_tournaments_paginated()
  end

  @doc """
  Returns a paginated list of tournaments in which the user's linked player has standings.
  Accepts the same filter/sort/pagination options as `list_tournaments_paginated/2`.
  """
  def list_played_tournaments_paginated(scope, opts \\ []) do
    user_id = scope.user.id

    # Subquery to find tournament IDs where the user's player has standings
    tournament_ids_query =
      from s in OP.Tournaments.Standing,
        join: p in OP.Players.Player,
        on: p.id == s.player_id,
        where: p.user_id == ^user_id,
        select: s.tournament_id,
        distinct: true

    opts
    |> Keyword.put(:base_query_fn, fn ->
      Tournament
      |> where([t], t.id in subquery(tournament_ids_query))
      |> preload([:organizer, [season: :league], :location, standings: :player])
    end)
    |> do_list_tournaments_paginated()
  end

  defp do_list_tournaments_paginated(opts) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 25)
    search = Keyword.get(opts, :search)
    location_id = Keyword.get(opts, :location_id)
    start_date = Keyword.get(opts, :start_date)
    end_date = Keyword.get(opts, :end_date)
    sort_by = Keyword.get(opts, :sort_by, :start_at)
    sort_dir = Keyword.get(opts, :sort_dir, :desc)
    base_query_fn = Keyword.fetch!(opts, :base_query_fn)

    base_query = base_query_fn.() |> apply_sort(sort_by, sort_dir)

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
  Gets a tournament by slug with preloaded associations.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament_by_slug!(current_scope, "my-tournament")
      %Tournament{}

      iex> get_tournament_by_slug!(current_scope, "unknown")
      ** (Ecto.NoResultsError)

  """
  def get_tournament_by_slug!(_scope, slug) when is_binary(slug) do
    Tournament
    |> preload([:organizer, :season, :location, standings: :player])
    |> Repo.get_by!(slug: slug)
  end

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(current_scope, %{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(scope, attrs \\ %{}) do
    attrs = maybe_put_user_tracking(attrs, scope, :create)

    %Tournament{}
    |> Tournament.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament.

  When meaningful_games changes, automatically recalculates TGP points for all standings.
  When season_id changes, recalculates rankings for both the old and new seasons.

  ## Examples

      iex> update_tournament(current_scope, tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(current_scope, tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(scope, %Tournament{} = tournament, attrs) do
    old_meaningful_games = tournament.meaningful_games
    old_season_id = tournament.season_id
    attrs = maybe_put_user_tracking(attrs, scope, :update)

    result =
      tournament
      |> Tournament.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        # Recalculate standings if meaningful_games changed
        result =
          if updated.meaningful_games != old_meaningful_games do
            recalculate_standings_points(scope, updated)
          else
            {:ok, Repo.preload(updated, [standings: :player], force: true)}
          end

        # Recalculate rankings if season changed
        maybe_recalculate_season_rankings(scope, old_season_id, updated.season_id)

        result

      error ->
        error
    end
  end

  @doc """
  Deletes a tournament.

  Recalculates season rankings after deletion if the tournament was assigned to a season.

  ## Examples

      iex> delete_tournament(current_scope, tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(current_scope, tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(scope, %Tournament{} = tournament) do
    season_id = tournament.season_id

    result = Repo.delete(tournament)

    case result do
      {:ok, deleted} ->
        # Recalculate rankings for the season the tournament was in
        if season_id do
          Leagues.recalculate_season_rankings(scope, season_id)
        end

        {:ok, deleted}

      error ->
        error
    end
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
  alias OP.Tournaments.TgpCalculator

  @doc """
  Recalculates and persists TGP points for all standings in a tournament.

  This function should be called when:
  - A tournament is imported
  - The meaningful_games value changes
  - Standings are added or removed

  ## Examples

      iex> recalculate_standings_points(scope, tournament)
      {:ok, %Tournament{}}

  """
  def recalculate_standings_points(_scope, %Tournament{} = tournament) do
    # Load standings if not preloaded
    tournament = Repo.preload(tournament, [standings: :player], force: true)
    standings = tournament.standings || []
    player_count = length(standings)
    meaningful_games = tournament.meaningful_games || 0

    if player_count == 0 or meaningful_games == 0 do
      {:ok, tournament}
    else
      # Calculate points for all positions
      points_by_position =
        TgpCalculator.calculate_all_points(player_count, meaningful_games)
        |> Map.new(&{&1.position, &1})

      # Batch update all standings
      Enum.each(standings, fn standing ->
        points = Map.get(points_by_position, standing.position, %{})

        standing
        |> Ecto.Changeset.change(%{
          linear_points: points[:linear_points] || 0.0,
          dynamic_points: points[:dynamic_points] || 0.0,
          total_points: points[:total_points] || 0.0
        })
        |> Repo.update!()
      end)

      # Reload tournament with updated standings
      {:ok, Repo.preload(tournament, [standings: :player], force: true)}
    end
  end

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

  defp maybe_put_user_tracking(attrs, %{user: %{id: user_id}}, :create) do
    attrs
    |> put_attr(:created_by_id, user_id)
    |> put_attr(:updated_by_id, user_id)
  end

  defp maybe_put_user_tracking(attrs, %{user: %{id: user_id}}, :update) do
    put_attr(attrs, :updated_by_id, user_id)
  end

  defp maybe_put_user_tracking(attrs, _scope, _action), do: attrs

  defp put_attr(attrs, key, value) when is_map(attrs) do
    string_keys? = attrs |> Map.keys() |> Enum.any?(&is_binary/1)

    if string_keys? do
      Map.put(attrs, to_string(key), value)
    else
      Map.put(attrs, key, value)
    end
  end

  defp maybe_recalculate_season_rankings(scope, old_season_id, new_season_id) do
    # Recalculate old season if it had a season
    if old_season_id && old_season_id != new_season_id do
      Leagues.recalculate_season_rankings(scope, old_season_id)
    end

    # Recalculate new season if it has a season
    if new_season_id do
      Leagues.recalculate_season_rankings(scope, new_season_id)
    end
  end
end
