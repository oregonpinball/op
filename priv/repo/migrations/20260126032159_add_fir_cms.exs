defmodule OP.Repo.Migrations.AddFirCms do
  use Ecto.Migration

  def change do
    create table(:fir_sections) do
      add :name, :string, null: false
      add :html_description, :text

      add :slug, :string, null: false
      add :state, :string, null: false, default: "drafting"

      add :parent_section_id, references(:fir_sections, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create table(:fir_pages) do
      add :name, :string, null: false
      add :html, :text
      # This is what shows up in the tile when viewing the section
      # it is in
      add :html_description, :text

      add :slug, :string, null: false
      add :state, :string, null: false, default: "drafting"

      add :publish_at, :utc_datetime
      add :section_id, references(:fir_sections, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:fir_sections, [:slug])
    create unique_index(:fir_pages, [:slug])
  end
end
