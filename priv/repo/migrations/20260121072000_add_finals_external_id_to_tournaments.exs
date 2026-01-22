defmodule OP.Repo.Migrations.AddFinalsExternalIdToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :finals_external_id, :string
    end
  end
end
