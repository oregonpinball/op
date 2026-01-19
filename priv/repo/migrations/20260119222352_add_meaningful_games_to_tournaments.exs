defmodule OP.Repo.Migrations.AddMeaningfulGamesToTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      add :meaningful_games, :float
    end
  end
end
