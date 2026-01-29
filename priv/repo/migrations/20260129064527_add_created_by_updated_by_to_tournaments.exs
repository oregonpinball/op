defmodule OP.Repo.Migrations.AddCreatedByUpdatedByToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :updated_by_id, references(:users, on_delete: :nilify_all)
    end

    create index(:tournaments, [:created_by_id])
    create index(:tournaments, [:updated_by_id])
  end
end
