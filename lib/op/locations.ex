defmodule OP.Locations do
  @moduledoc """
  The Locations context.
  """

  import Ecto.Query, warn: false
  alias OP.Repo

  alias OP.Accounts.Scope
  alias OP.Locations.Location

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations(current_scope)
      [%Location{}, ...]

  """
  def list_locations(%Scope{} = _current_scope) do
    Repo.all(Location)
  end

  # Fall back for when `scope` is `nil` for public access
  def list_locations(_) do
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
  def get_location!(%Scope{} = _current_scope, id), do: Repo.get!(Location, id)

  # Fall back for when `scope` is `nil` for public access
  def get_location!(_, id), do: Repo.get!(Location, id)

  @doc """
  Gets a location by slug.

  ## Examples

      iex> get_location_by_slug(current_scope, "my-location")
      %Location{}

      iex> get_location_by_slug(current_scope, "unknown")
      nil

  """
  def get_location_by_slug(%Scope{} = _current_scope, slug) when is_binary(slug) do
    Repo.get_by(Location, slug: slug)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_location_by_slug(_, slug) when is_binary(slug) do
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
  def get_location_by_external_id(%Scope{} = _current_scope, external_id) when is_binary(external_id) do
    Repo.get_by(Location, external_id: external_id)
  end

  # Fall back for when `scope` is `nil` for public access
  def get_location_by_external_id(_, external_id) when is_binary(external_id) do
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
  def create_location(scope, attrs \\ %{})

  def create_location(%Scope{} = _current_scope, attrs) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  # Fall back for when `scope` is `nil` for public access
  def create_location(_, attrs) do
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
  def update_location(%Scope{} = _current_scope, %Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  # Fall back for when `scope` is `nil` for public access
  def update_location(_, %Location{} = location, attrs) do
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
  def delete_location(%Scope{} = _current_scope, %Location{} = location) do
    Repo.delete(location)
  end

  # Fall back for when `scope` is `nil` for public access
  def delete_location(_, %Location{} = location) do
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
end
