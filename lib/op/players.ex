defmodule OP.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Players.Player

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players(current_scope)
      [%Player{}, ...]

  """
  def list_players(_scope) do
    Repo.all(Player)
  end

  @doc """
  Returns the list of players with preloaded associations.

  ## Examples

      iex> list_players_with_preloads(current_scope)
      [%Player{}, ...]

  """
  def list_players_with_preloads(_scope) do
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
  def get_player!(_scope, id), do: Repo.get!(Player, id)

  @doc """
  Gets a single player with preloaded associations.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player_with_preloads!(current_scope, 123)
      %Player{}

      iex> get_player_with_preloads!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_player_with_preloads!(_scope, id) do
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
  def get_player_by_slug(_scope, slug) when is_binary(slug) do
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
  def get_player_by_external_id(_scope, external_id) when is_binary(external_id) do
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
  def create_player(_scope, attrs \\ %{}) do
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
  def update_player(_scope, %Player{} = player, attrs) do
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
  def delete_player(_scope, %Player{} = player) do
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

  @doc """
  Searches players by name using a case-insensitive partial match.

  ## Examples

      iex> search_players(current_scope, "john")
      [%Player{name: "John Doe"}, ...]

  """
  def search_players(_scope, query) when is_binary(query) and byte_size(query) > 0 do
    search_term = "%#{query}%"

    Player
    |> where([p], like(fragment("lower(?)", p.name), fragment("lower(?)", ^search_term)))
    |> order_by([p], asc: p.name)
    |> limit(10)
    |> Repo.all()
  end

  def search_players(_scope, _query), do: []

  @doc """
  Gets a player by slug, raising if not found.

  Returns the player with preloaded user association.

  ## Examples

      iex> get_player_by_slug!(current_scope, "my-player")
      %Player{}

      iex> get_player_by_slug!(current_scope, "unknown")
      ** (Ecto.NoResultsError)

  """
  def get_player_by_slug!(_scope, slug) when is_binary(slug) do
    Player
    |> preload([:user])
    |> Repo.get_by!(slug: slug)
  end

  @doc """
  Scrubs (anonymizes) a player record.

  Instead of deleting, this function:
  - Sets name to "Deleted Player"
  - Clears external_id
  - Removes user_id link
  - Regenerates slug

  This preserves the record for historical tournament data while
  removing personally identifiable information.

  ## Examples

      iex> scrub_player(current_scope, player)
      {:ok, %Player{name: "Deleted Player", external_id: nil, user_id: nil}}

  """
  def scrub_player(_scope, %Player{} = player) do
    player
    |> Player.scrub_changeset()
    |> Repo.update()
  end

  @doc """
  Links a user account to a player.

  ## Examples

      iex> link_user(current_scope, player, user_id)
      {:ok, %Player{user_id: user_id}}

  """
  def link_user(_scope, %Player{} = player, user_id) when is_integer(user_id) do
    player
    |> Ecto.Changeset.change(user_id: user_id)
    |> Repo.update()
  end

  @doc """
  Unlinks the user account from a player.

  ## Examples

      iex> unlink_user(current_scope, player)
      {:ok, %Player{user_id: nil}}

  """
  def unlink_user(_scope, %Player{} = player) do
    player
    |> Ecto.Changeset.change(user_id: nil)
    |> Repo.update()
  end
end
