defmodule OP.Repo.Migrations.AddTotalsToRankings do
  use Ecto.Migration

  def change do
    alter table(:rankings) do
      add :total_points, :float, default: 0.0
      add :event_count, :integer, default: 0
    end
  end
end
