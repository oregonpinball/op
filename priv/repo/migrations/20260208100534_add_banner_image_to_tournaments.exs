defmodule OP.Repo.Migrations.AddBannerImageToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :banner_image, :string
    end
  end
end
