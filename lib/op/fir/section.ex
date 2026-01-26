defmodule OP.Fir.Section do
  use Ecto.Schema
  use OP.Sluggable

  import Ecto.Changeset

  alias OP.Fir.{Page, Section}

  schema "fir_sections" do
    field :name, :string
    field :html_description, :string
    field :slug, :string

    field :state, Ecto.Enum,
      values: [:drafting, :published, :archived],
      default: :drafting

    belongs_to :parent_section, Section
    has_many :child_sections, Section, foreign_key: :parent_section_id
    has_many :pages, Page

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [
      :name,
      :html_description,
      :slug,
      :state,
      :parent_section_id
    ])
    |> generate_slug()
    |> validate_required([:name, :slug, :state])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:parent_section_id)
    |> prevent_circular_parent()
  end

  # Prevents a section from being its own parent
  defp prevent_circular_parent(changeset) do
    parent_id = get_change(changeset, :parent_section_id)
    section_id = get_field(changeset, :id)

    if parent_id && section_id && parent_id == section_id do
      add_error(changeset, :parent_section_id, "cannot be the same as the section itself")
    else
      changeset
    end
  end
end
