defmodule OP.Repo.Migrations.AddRankingCalculationMethodToSeasons do
  use Ecto.Migration

  def change do
    alter table(:seasons) do
      add :ranking_calculation_method, :string, null: false, default: "oppr_v1_0"
    end
  end
end
