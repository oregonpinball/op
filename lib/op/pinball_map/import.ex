defmodule OP.PinballMap.Import do
  @moduledoc """
  Orchestrates importing pinball venue locations from Pinball Map API.
  """

  require Logger

  alias OP.Accounts.Scope
  alias OP.Locations
  alias OP.PinballMap.Client

  @default_regions ["portland", "eugene", "southern-oregon"]

  @doc """
  Imports locations from the given Pinball Map regions.

  Fetches locations from each region's API endpoint and upserts them into
  the database. Continues processing on individual region failures.

  ## Options
    * `:regions` - List of region names (defaults to Oregon regions)
    * `:client` - Pre-configured client (optional, creates default)

  Returns `{:ok, summary}` where summary contains counts of created, updated,
  errors, and regions processed.
  """
  def import_regions(opts \\ []) do
    regions = Keyword.get(opts, :regions, @default_regions)
    client = Keyword.get(opts, :client, Client.new())
    scope = Scope.for_user(nil)

    summary = %{created: 0, updated: 0, errors: 0, regions_processed: 0}

    summary =
      Enum.reduce(regions, summary, fn region, acc ->
        case Client.get_region_locations(client, region) do
          {:ok, locations} ->
            Logger.info("Fetched #{length(locations)} locations from region #{region}")

            region_summary =
              Enum.reduce(locations, %{created: 0, updated: 0, errors: 0}, fn location_data,
                                                                              region_acc ->
                case Locations.upsert_from_pinball_map(scope, location_data) do
                  {:ok, _location, :created} ->
                    %{region_acc | created: region_acc.created + 1}

                  {:ok, _location, :updated} ->
                    %{region_acc | updated: region_acc.updated + 1}

                  {:error, changeset} ->
                    Logger.warning("Failed to upsert location: #{inspect(changeset.errors)}")
                    %{region_acc | errors: region_acc.errors + 1}
                end
              end)

            %{
              acc
              | created: acc.created + region_summary.created,
                updated: acc.updated + region_summary.updated,
                errors: acc.errors + region_summary.errors,
                regions_processed: acc.regions_processed + 1
            }

          {:error, error} ->
            Logger.error("Failed to fetch region #{region}: #{inspect(error)}")
            %{acc | errors: acc.errors + 1}
        end
      end)

    {:ok, summary}
  end
end
