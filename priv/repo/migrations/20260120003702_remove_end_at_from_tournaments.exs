defmodule OP.Repo.Migrations.RemoveEndAtFromTournaments do
  use Ecto.Migration

  def change do
    drop index(:tournaments, [:end_at])

    alter table(:tournaments) do
      remove :end_at, :utc_datetime
    end
  end
end
