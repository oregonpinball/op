defmodule OP.TournamentsFixtures do
  @moduledoc """
  Test helpers for creating tournament and standing entities.
  """

  alias OP.Repo
  alias OP.Tournaments
  alias OP.Tournaments.Standing

  def unique_tournament_name, do: "Tournament #{System.unique_integer([:positive])}"

  def valid_tournament_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_tournament_name(),
      start_at: DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)
    })
  end

  def tournament_fixture(scope \\ nil, attrs \\ %{}) do
    {:ok, tournament} =
      attrs
      |> valid_tournament_attributes()
      |> then(&Tournaments.create_tournament(scope, &1))

    tournament
  end

  def tournament_with_external_id_fixture(scope \\ nil, external_id, attrs \\ %{}) do
    {:ok, tournament} =
      attrs
      |> valid_tournament_attributes()
      |> Map.put(:external_id, external_id)
      |> then(&Tournaments.create_tournament(scope, &1))

    tournament
  end

  def standing_fixture(tournament, player, attrs \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    standing_attrs =
      Map.merge(
        %{
          tournament_id: tournament.id,
          player_id: player.id,
          position: attrs[:position] || 1,
          is_finals: false,
          opted_out: false,
          inserted_at: now,
          updated_at: now
        },
        Map.drop(attrs, [:position])
      )

    {1, [standing]} = Repo.insert_all(Standing, [standing_attrs], returning: true)
    standing
  end
end
