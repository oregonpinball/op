defmodule OP.Sluggable do
  @moduledoc """
  Provides slug generation functionality for Ecto schemas.

  ## Usage

  Add `use OP.Sluggable` to your schema module to inject the `generate_slug/1`
  function into your changeset pipeline:

      defmodule OP.Players.Player do
        use Ecto.Schema
        use OP.Sluggable
        import Ecto.Changeset

        schema "players" do
          field :slug, :string
          # ...
        end

        def changeset(player, attrs) do
          player
          |> cast(attrs, [:name])
          |> generate_slug()
          |> validate_required([:slug])
        end
      end

  The `generate_slug/1` function will automatically generate a slug using Nanoid
  if one is not already present in the changeset.
  """

  defmacro __using__(_opts) do
    quote do
      import Ecto.Changeset

      # Generates a slug for the changeset if one is not already present.
      # Uses Nanoid to generate a unique, URL-safe slug.
      defp generate_slug(changeset) do
        if get_field(changeset, :slug) do
          changeset
        else
          put_change(changeset, :slug, Nanoid.generate())
        end
      end
    end
  end
end
