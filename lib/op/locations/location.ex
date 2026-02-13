defmodule OP.Locations.Location do
  use Ecto.Schema
  use OP.Sluggable
  import Ecto.Changeset

  schema "locations" do
    field :external_id, :string
    field :name, :string
    field :slug, :string

    # 3728 NE Sandy Blvd
    field :address, :string
    field :address_2, :string
    # Portland, ideally auto-filled from postal
    field :city, :string
    # Oregon, ideally auto-filled from postal
    field :state, :string
    field :country, :string
    # Zip or postal code, e.g. 97232
    field :postal_code, :string

    # For plotting on a map itself, if ever needed
    field :latitude, :float
    field :longitude, :float

    field :pinball_map_id, :integer

    # Path to uploaded banner image
    field :banner_image, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :external_id,
      :name,
      :slug,
      :address,
      :address_2,
      :city,
      :state,
      :country,
      :postal_code,
      :latitude,
      :longitude,
      :pinball_map_id,
      :banner_image
    ])
    |> generate_slug()
    |> validate_required([:name])
    |> unique_constraint(:external_id)
    |> unique_constraint(:pinball_map_id)
    |> unique_constraint(:slug)
  end
end
