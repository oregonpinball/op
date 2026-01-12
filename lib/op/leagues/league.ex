defmodule OP.Leagues.League do
  use Ecto.Schema
  use OP.Sluggable
  import Ecto.Changeset

  alias OP.Accounts.User

  schema "leagues" do
    field :name, :string
    # HTML-formatted column to integrate with TipTap
    field :description, :string

    # Publicly-usable URL slug for profile access
    field :slug, :string

    belongs_to :author, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(league, attrs) do
    league
    |> cast(attrs, [:name, :description, :slug, :author_id])
    |> generate_slug()
    |> validate_required([:name, :author_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:slug, min: 2, max: 255)
    |> unique_constraint(:slug)
  end
end
