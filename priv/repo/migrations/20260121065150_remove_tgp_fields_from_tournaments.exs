defmodule OP.Repo.Migrations.RemoveTgpFieldsFromTournaments do
  use Ecto.Migration

  def change do
    alter table(:tournaments) do
      remove :tgp, :float
      remove :tgp_config, :map
      remove :base_value, :float
      remove :tva_rating, :float
      remove :tva_ranking, :float
      remove :total_tva, :float
      remove :event_booster_multiplier, :float
      remove :first_place_value, :float
      remove :event_booster, :string
      remove :allows_opt_out, :boolean
    end
  end
end
