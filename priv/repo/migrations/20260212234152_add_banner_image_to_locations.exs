defmodule OP.Repo.Migrations.AddBannerImageToLocations do
  use Ecto.Migration

  def change do
    alter table(:locations) do
      add :banner_image, :string
    end
  end
end
