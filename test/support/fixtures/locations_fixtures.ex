defmodule OP.LocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OP.Locations` context.
  """

  alias OP.Accounts.Scope

  def unique_location_name, do: "Location #{System.unique_integer()}"

  def valid_location_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_location_name(),
      address: "123 Main St",
      city: "Portland",
      state: "OR",
      postal_code: "97201",
      country: "USA"
    })
  end

  def location_fixture(attrs \\ %{}) do
    scope = attrs[:scope] || Scope.for_user(nil)

    {:ok, location} =
      attrs
      |> valid_location_attributes()
      |> then(&OP.Locations.create_location(scope, &1))

    location
  end

  def location_with_external_id_fixture(external_id, attrs \\ %{}) do
    scope = attrs[:scope] || Scope.for_user(nil)

    {:ok, location} =
      attrs
      |> valid_location_attributes()
      |> Map.put(:external_id, external_id)
      |> then(&OP.Locations.create_location(scope, &1))

    location
  end
end
