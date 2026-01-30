defmodule OP.Players.Player do
  use Ecto.Schema
  use OP.Sluggable
  import Ecto.Changeset

  alias OP.Accounts.User

  schema "players" do
    field :external_id, :string
    field :name, :string
    field :number, :integer

    # Publicly-usable URL slug for profile access
    field :slug, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :external_id, :number])
    |> generate_slug()
    |> generate_number()
    |> validate_required([:name, :slug, :number])
    |> unique_constraint(:number)
  end

  @doc """
  Changeset for scrubbing (anonymizing) a player.

  Sets standard anonymized values and regenerates the slug.
  This preserves the record for historical tournament data while
  removing personally identifiable information.
  """
  def scrub_changeset(player) do
    player
    |> change(%{
      name: "Deleted Player",
      external_id: nil,
      user_id: nil,
      slug: nil
    })
    |> generate_slug()
    |> validate_required([:name, :slug])
  end

  defp generate_number(changeset) do
    if get_field(changeset, :number) do
      changeset
    else
      put_change(changeset, :number, Enum.random(1000..9999))
    end
  end
end
