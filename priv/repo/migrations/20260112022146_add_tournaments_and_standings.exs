defmodule OP.Repo.Migrations.AddTournamentsAndStandings do
  use Ecto.Migration

  def change do
    create table(:tournaments) do
      add :external_id, :string
      add :external_url, :string
      add :name, :string, null: false
      add :description, :text
      add :start_at, :utc_datetime, null: false
      add :end_at, :utc_datetime
      add :tgp_config, :map
      add :event_booster, :string, default: "none"
      add :qualifying_format, :string, default: "none"
      add :allows_opt_out, :boolean, default: false
      add :base_value, :float
      add :tva_rating, :float
      add :tva_ranking, :float
      add :total_tva, :float
      add :tgp, :float
      add :event_booster_multiplier, :float
      add :first_place_value, :float
      add :organizer_id, references(:users, on_delete: :nilify_all)
      add :season_id, references(:seasons, on_delete: :nilify_all)
      add :location_id, references(:locations, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:tournaments, [:organizer_id])
    create index(:tournaments, [:season_id])
    create index(:tournaments, [:location_id])
    create index(:tournaments, [:start_at])
    create index(:tournaments, [:end_at])

    create table(:standings) do
      add :position, :integer
      add :is_finals, :boolean, default: false
      add :opted_out, :boolean, default: false
      add :linear_points, :float, default: 0.0
      add :dynamic_points, :float, default: 0.0
      add :age_in_days, :integer, default: 0
      add :decay_multiplier, :float, default: 1.0
      add :total_points, :float
      add :decayed_points, :float
      add :efficiency, :float
      add :tournament_id, references(:tournaments, on_delete: :delete_all), null: false
      add :player_id, references(:players, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:standings, [:player_id])
    create index(:standings, [:tournament_id, :position])
  end
end
