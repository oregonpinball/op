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
    |> preload([:organizer, :season, :location, :standings])
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
end
