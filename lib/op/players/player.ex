defmodule OP.Players.Player do
  use Ecto.Schema
  use OP.Sluggable
  import Ecto.Changeset

  alias OP.Accounts.User

  schema "players" do
    field :external_id, :string
    field :name, :string

    # Publicly-usable URL slug for profile access
    field :slug, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :external_id])
    |> generate_slug()
    |> validate_required([:name, :slug])
  end
end
