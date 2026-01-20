defmodule OP.LeaguesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OP.Leagues` context.
  """

  import OP.AccountsFixtures

  alias OP.Accounts.Scope

  def unique_league_name, do: "League #{System.unique_integer()}"
  def unique_season_name, do: "Season #{System.unique_integer()}"

  def valid_league_attributes(attrs \\ %{}) do
    # Ensure author_id is provided
    author_id = attrs[:author_id] || create_user_for_league()

    Enum.into(attrs, %{
      name: unique_league_name(),
      description: "A test league",
      author_id: author_id
    })
  end

  defp create_user_for_league do
    user_fixture().id
  end

  def valid_season_attributes(attrs \\ %{}) do
    now = DateTime.utc_now()
    start_at = Map.get(attrs, :start_at, now)
    end_at = Map.get(attrs, :end_at, DateTime.add(start_at, 90, :day))

    Enum.into(attrs, %{
      name: unique_season_name(),
      start_at: start_at,
      end_at: end_at
    })
  end

  def league_fixture(attrs \\ %{}) do
    scope = attrs[:scope] || Scope.for_user(nil)

    {:ok, league} =
      attrs
      |> valid_league_attributes()
      |> then(&OP.Leagues.create_league(scope, &1))

    league
  end

  def season_fixture(league, attrs \\ %{}) do
    scope = attrs[:scope] || Scope.for_user(nil)

    {:ok, season} =
      attrs
      |> valid_season_attributes()
      |> Map.put(:league_id, league.id)
      |> then(&OP.Leagues.create_season(scope, &1))

    season
  end
end
