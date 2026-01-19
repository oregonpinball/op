defmodule OP.Repo.Migrations.AddLocations do
  use Ecto.Migration

  def change do
    create table(:locations) do
      add :external_id, :string
      add :slug, :string
      add :name, :string
      add :address, :string
      add :address_2, :string
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string
      add :latitude, :float
      add :longitude, :float

      timestamps(type: :utc_datetime)
    end
  end
end
