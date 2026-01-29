defmodule OP.Repo.Migrations.AddFinalsFormatToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :finals_format, :string, default: "none"
    end
  end
end
