defmodule OP.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Locations.Location

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations(current_scope)
      [%Location{}, ...]

  """
  def list_locations(_scope) do
    Repo.all(Location)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(current_scope, 123)
      %Location{}

      iex> get_location!(current_scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(_scope, id), do: Repo.get!(Location, id)

  @doc """
  Gets a location by slug.

  ## Examples

      iex> get_location_by_slug(current_scope, "my-location")
      %Location{}

      iex> get_location_by_slug(current_scope, "unknown")
      nil

  """
  def get_location_by_slug(_scope, slug) when is_binary(slug) do
    Repo.get_by(Location, slug: slug)
  end

  @doc """
  Gets a location by external_id.

  ## Examples

      iex> get_location_by_external_id(current_scope, "ext-123")
      %Location{}

      iex> get_location_by_external_id(current_scope, "unknown")
      nil

  """
  def get_location_by_external_id(_scope, external_id) when is_binary(external_id) do
    Repo.get_by(Location, external_id: external_id)
  end

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(current_scope, %{field: value})
      {:ok, %Location{}}

      iex> create_location(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(_scope, attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(current_scope, location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(current_scope, location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(_scope, %Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location(current_scope, location)
      {:ok, %Location{}}

      iex> delete_location(current_scope, location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(_scope, %Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{data: %Location{}}

  """
  def change_location(%Location{} = location, attrs \\ %{}) do
    Location.changeset(location, attrs)
  end

  @doc """
  Finds a location by matching external_id or name (case-insensitive).
  Prioritizes external_id match.

  ## Examples

      iex> find_location_by_match(scope, "matchplay:123", "Test Location")
      %Location{}

      iex> find_location_by_match(scope, nil, nil)
      nil

  """
  def find_location_by_match(_scope, nil, nil), do: nil

  def find_location_by_match(scope, external_id, name) do
    # First try external_id match
    location = if external_id, do: get_location_by_external_id(scope, external_id)

    # Fall back to case-insensitive name match
    location || find_location_by_name(scope, name)
  end

  @doc """
  Lists tournaments at a given location, preloading season and league.

  ## Examples

      iex> list_tournaments_at_location(current_scope, 1)
      [%Tournament{}, ...]

  """
  def list_tournaments_at_location(_scope, location_id) do
    alias OP.Tournaments.Tournament

    Tournament
    |> where([t], t.location_id == ^location_id)
    |> order_by([t], [desc: t.start_at])
    |> limit(10)
    |> preload([season: :league])
    |> Repo.all()
  end

  @doc """
  Finds a location by name (case-insensitive).

  ## Examples

      iex> find_location_by_name(scope, "Test Location")
      %Location{}

      iex> find_location_by_name(scope, "Unknown")
      nil

  """
  def find_location_by_name(_scope, nil), do: nil
  def find_location_by_name(_scope, ""), do: nil

  def find_location_by_name(_scope, name) do
    Location
    |> where([l], fragment("lower(?)", l.name) == ^String.downcase(name))
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Finds an existing location by external_id or name, or creates a new one from Matchplay data.

  ## Examples

      iex> find_or_create_location_from_matchplay(scope, %{"locationId" => 123, "name" => "Test"})
      {:ok, %Location{}}

      iex> find_or_create_location_from_matchplay(scope, nil)
      {:ok, nil}

  """
  def find_or_create_location_from_matchplay(_scope, nil), do: {:ok, nil}

  def find_or_create_location_from_matchplay(scope, location_data) do
    external_id = if id = location_data["locationId"], do: "matchplay:#{id}"
    name = location_data["name"]

    case find_location_by_match(scope, external_id, name) do
      %Location{} = location ->
        {:ok, location, false}

      nil ->
        case create_location(scope, %{
               name: name,
               external_id: external_id,
               address: location_data["address"]
             }) do
          {:ok, location} -> {:ok, location, true}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end
end
