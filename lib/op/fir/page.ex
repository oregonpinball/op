defmodule OP.Fir.Page do
  use Ecto.Schema
  use OP.Sluggable

  import Ecto.Changeset

  alias OP.Fir.Section

  schema "fir_pages" do
    field :name, :string
    field :html, :string
    field :html_description, :string
    field :slug, :string

    field :state, Ecto.Enum,
      values: [:drafting, :published, :archived],
      default: :drafting

    field :publish_at, :utc_datetime

    belongs_to :section, Section

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [
      :name,
      :html,
      :html_description,
      :slug,
      :state,
      :publish_at,
      :section_id
    ])
    |> generate_slug()
    |> validate_required([:name, :slug, :state])
    |> validate_length(:name, min: 1, max: 255)
    |> foreign_key_constraint(:section_id)
    |> validate_publish_at()
  end

  # Ensures publish_at is set when state is published
  defp validate_publish_at(changeset) do
    state = get_field(changeset, :state)
    publish_at = get_field(changeset, :publish_at)

    if state == :published && is_nil(publish_at) do
      put_change(changeset, :publish_at, DateTime.truncate(DateTime.utc_now(), :second))
    else
      changeset
    end
  end
end
