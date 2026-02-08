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
  Returns a paginated list of locations with optional search.

  ## Options

    * `:page` - Current page number (default: 1)
    * `:per_page` - Items per page (default: 25)
    * `:search` - Location name search string
    * `:sort_by` - Field to sort by (default: `:name`). Allowed: `:name`, `:city`, `:state`
    * `:sort_dir` - Sort direction (default: `:asc`). Allowed: `:asc`, `:desc`

  ## Returns

    A tuple `{locations, pagination_meta}` where pagination_meta contains:
    * `:page` - Current page
    * `:per_page` - Items per page
    * `:total_count` - Total number of matching locations
    * `:total_pages` - Total number of pages

  """
  def list_locations_paginated(_scope, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 25)
    search = Keyword.get(opts, :search)
    sort_by = Keyword.get(opts, :sort_by, :name)
    sort_dir = Keyword.get(opts, :sort_dir, :asc)

    base_query =
      Location
      |> apply_location_sort(sort_by, sort_dir)

    filtered_query = filter_locations_by_search(base_query, search)

    total_count = Repo.aggregate(filtered_query, :count, :id)
    total_pages = ceil(total_count / per_page)

    locations =
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

    {locations, pagination_meta}
  end

  @sortable_fields ~w(name city state)a

  defp apply_location_sort(query, field, dir)
       when field in @sortable_fields and dir in [:asc, :desc] do
    order_by(query, [l], [{^dir, field(l, ^field)}])
  end

  defp apply_location_sort(query, _field, _dir) do
    order_by(query, [l], asc: l.name)
  end

  defp filter_locations_by_search(query, nil), do: query
  defp filter_locations_by_search(query, ""), do: query

  defp filter_locations_by_search(query, search) do
    search_term = "%#{String.downcase(search)}%"
    where(query, [l], like(fragment("lower(?)", l.name), ^search_term))
  end

  @doc """
  Searches locations by name (case-insensitive partial match).

  ## Examples

      iex> search_locations(current_scope, "arcade")
      [%Location{name: "Fun Arcade"}, ...]

  """
  def search_locations(_scope, query) when is_binary(query) and byte_size(query) > 0 do
    search_term = "%#{query}%"

    Location
    |> where([l], like(fragment("lower(?)", l.name), fragment("lower(?)", ^search_term)))
    |> order_by([l], asc: l.name)
    |> limit(10)
    |> Repo.all()
  end

  def search_locations(_scope, _query), do: []

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
    |> order_by([t], desc: t.start_at)
    |> limit(10)
    |> preload(season: :league)
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
  Upserts a location from Pinball Map API data.

  Looks up an existing location by `pinball_map_id`. If found, updates it.
  If not found, creates a new one.

  Returns `{:ok, location, :created | :updated}` or `{:error, changeset}`.
  """
  def upsert_from_pinball_map(_scope, api_data) when is_map(api_data) do
    pinball_map_id = api_data["id"]

    attrs = %{
      pinball_map_id: pinball_map_id,
      name: api_data["name"],
      address: api_data["street"],
      city: api_data["city"],
      state: api_data["state"],
      postal_code: api_data["zip"],
      country: api_data["country"],
      latitude: parse_coordinate(api_data["lat"]),
      longitude: parse_coordinate(api_data["lon"])
    }

    case Repo.get_by(Location, pinball_map_id: pinball_map_id) do
      %Location{} = location ->
        case location |> Location.changeset(attrs) |> Repo.update() do
          {:ok, location} -> {:ok, location, :updated}
          {:error, changeset} -> {:error, changeset}
        end

      nil ->
        case %Location{} |> Location.changeset(attrs) |> Repo.insert() do
          {:ok, location} -> {:ok, location, :created}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  defp parse_coordinate(nil), do: nil
  defp parse_coordinate(value) when is_float(value), do: value
  defp parse_coordinate(value) when is_integer(value), do: value / 1

  defp parse_coordinate(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
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
