defmodule OP.Repo.Migrations.AddSlugToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :slug, :string
    end

    create unique_index(:tournaments, [:slug])
  end
end
