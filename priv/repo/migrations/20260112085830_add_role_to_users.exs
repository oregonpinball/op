defmodule OP.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "player", null: false
    end

    create index(:users, [:role])
  end
end
