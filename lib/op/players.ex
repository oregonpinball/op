defmodule OP.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Accounts.Scope
  alias OP.Players.Player

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players(current_scope)
      [%Player{}, ...]

  """
  def list_players(%Scope{} = _current_scope) do
    Repo.all(Player)
  end

  # Fall back for when `scope` is `nil` for public access
  def list_players(_) do
    Repo.all(Player)
  end

  @doc """
  Returns the list of players with preloaded associations.

  ## Examples

      iex> list_players_with_preloads(current_scope)
      [%Player{}, ...]

  """
  def list_players_with_preloads(%Scope{} = _current_scope) do
    Player
    |> preload([:user])
    |> Repo.all()
  end

  # Fall back for when `scope` is `nil` for public access
  def list_players_with_preloads(_) do
    Player
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(current_scope, 123)
      %Player{}

      iex> get_player!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(%Scope{} = _current_scope, id), do: Repo.get!(Player, id)

  # Fall back for when `scope` is `nil` for public access
  def get_player!(_, id), do: Repo.get!(Player, id)

  @doc """
  Gets a single player with preloaded associations.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player_with_preloads!(current_scope, 123)
      %Player{}

      iex> get_player_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_player_with_preloads!(%Scope{} = _current_scope, id) do
    Player
    |> preload([:user])
    |> Repo.get!(id)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_player_with_preloads!(_, id) do
    Player
    |> preload([:user])
    |> Repo.get!(id)
  end

  @doc """
  Gets a player by slug.

  ## Examples

      iex> get_player_by_slug(current_scope, "my-player")
      %Player{}

      iex> get_player_by_slug(current_scope, "unknown")
      nil

  """
  def get_player_by_slug(%Scope{} = _current_scope, slug) when is_binary(slug) do
    Repo.get_by(Player, slug: slug)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_player_by_slug(_, slug) when is_binary(slug) do
    Repo.get_by(Player, slug: slug)
  end

  @doc """
  Gets a player by external_id.

  ## Examples

      iex> get_player_by_external_id(current_scope, "ext-123")
      %Player{}

      iex> get_player_by_external_id(current_scope, "unknown")
      nil

  """
  def get_player_by_external_id(%Scope{} = _current_scope, external_id) when is_binary(external_id) do
    Repo.get_by(Player, external_id: external_id)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_player_by_external_id(_, external_id) when is_binary(external_id) do
    Repo.get_by(Player, external_id: external_id)
  end

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(current_scope, %{field: value})
      {:ok, %Player{}}

      iex> create_player(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(scope, attrs \\ %{})

  def create_player(%Scope{} = _current_scope, attrs) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  # Fall back for when `scope` is `nil` for public access
  def create_player(_, attrs) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(current_scope, player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(current_scope, player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Scope{} = _current_scope, %Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  # Fall back for when `scope` is `nil` for public access
  def update_player(_, %Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(current_scope, player)
      {:ok, %Player{}}

      iex> delete_player(current_scope, player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Scope{} = _current_scope, %Player{} = player) do
    Repo.delete(player)
  end

  # Fall back for when `scope` is `nil` for public access
  def delete_player(_, %Player{} = player) do
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end
end
