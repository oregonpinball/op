defmodule OP.Repo.Migrations.RenameSeasonRankingsToRankings do
  use Ecto.Migration

  def change do
    # Rename the table
    rename table(:season_rankings), to: table(:rankings)

    # Note: In SQLite, indexes are automatically updated when a table is renamed
    # No need to manually drop and recreate indexes
  end
end
