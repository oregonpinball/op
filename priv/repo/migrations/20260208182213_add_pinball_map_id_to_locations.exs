defmodule OP.Repo.Migrations.AddPinballMapIdToLocations do
  use Ecto.Migration

  def change do
    alter table(:locations) do
      add :pinball_map_id, :integer
    end

    create unique_index(:locations, [:pinball_map_id])
  end
end
