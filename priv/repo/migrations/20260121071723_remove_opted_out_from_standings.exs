defmodule OP.Repo.Migrations.RemoveOptedOutFromStandings do
  use Ecto.Migration

  def change do
    alter table(:standings) do
      remove :opted_out, :boolean, default: false
    end
  end
end
