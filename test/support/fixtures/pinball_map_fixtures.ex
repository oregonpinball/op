defmodule OP.PinballMapFixtures do
  @moduledoc """
  Test fixtures for Pinball Map API responses.
  """

  @doc """
  Returns a sample Pinball Map location API response entry.
  """
  def pinball_map_location(attrs \\ %{}) do
    Map.merge(
      %{
        "id" => 1234,
        "name" => "Ground Kontrol",
        "street" => "511 NW Couch St",
        "city" => "Portland",
        "state" => "OR",
        "zip" => "97209",
        "country" => "US",
        "lat" => "45.5237",
        "lon" => "-122.6782",
        "num_machines" => 40
      },
      attrs
    )
  end

  @doc """
  Returns a sample region locations API response with multiple locations.
  """
  def region_locations_response(locations \\ nil) do
    %{"locations" => locations || default_locations()}
  end

  @doc """
  Returns a list of sample Pinball Map locations.
  """
  def default_locations do
    [
      pinball_map_location(),
      pinball_map_location(%{
        "id" => 5678,
        "name" => "QuarterWorld Arcade",
        "street" => "4811 SE Hawthorne Blvd",
        "city" => "Portland",
        "state" => "OR",
        "zip" => "97215",
        "lat" => "45.5118",
        "lon" => "-122.6155"
      })
    ]
  end
end
