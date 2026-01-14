defmodule OP.PlayersFixtures do
  @moduledoc """
  Test helpers for creating player entities.
  """

  alias OP.Players

  def unique_player_name, do: "Player #{System.unique_integer([:positive])}"

  def valid_player_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_player_name()
    })
  end

  def player_fixture(scope \\ nil, attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> valid_player_attributes()
      |> then(&Players.create_player(scope, &1))

    player
  end

  def player_with_external_id_fixture(scope \\ nil, external_id, attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> valid_player_attributes()
      |> Map.put(:external_id, external_id)
      |> then(&Players.create_player(scope, &1))

    player
  end
end
