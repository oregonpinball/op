defmodule OP.Repo.Migrations.AddLeaguesSeasonsAndSeasonRankings do
  use Ecto.Migration

  def change do
    create table(:leagues) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string
      add :author_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:leagues, [:slug])
    create index(:leagues, [:author_id])

    create table(:seasons) do
      add :name, :string, null: false
      add :description, :text
      add :slug, :string
      add :start_at, :utc_datetime
      add :end_at, :utc_datetime
      add :league_id, references(:leagues, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:seasons, [:slug])
    create index(:seasons, [:league_id])

    create table(:season_rankings) do
      add :is_rated, :boolean, default: false, null: false
      add :rating, :float, default: 1500.0
      add :rating_deviation, :float, default: 200.0
      add :ranking, :integer
      add :player_id, references(:players, on_delete: :nothing), null: false
      add :season_id, references(:seasons, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:season_rankings, [:player_id, :season_id])
    create index(:season_rankings, [:player_id])
    create index(:season_rankings, [:season_id])
  end
end
