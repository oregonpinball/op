defmodule OP.Repo.Migrations.AddPlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string, null: false
      add :external_id, :string
      add :number, :integer
      add :slug, :string

      # Even if the user because un-authenticatable (e.g. deleted)
      # we probably want to keep the Player records around for historical
      # purposes.  We can look into scrubbing/anonymizing the data on delete
      # if needed in the future.
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:players, [:number])
    create index(:players, [:external_id])
    create index(:players, [:slug])
  end
end
