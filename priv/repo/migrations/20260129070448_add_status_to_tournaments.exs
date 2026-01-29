defmodule OP.Repo.Migrations.AddStatusToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :status, :string, null: false, default: "draft"
    end
  end
end
