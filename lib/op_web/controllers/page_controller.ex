defmodule OPWeb.PageController do
  use OPWeb, :controller

  def home(conn, _params) do
    if OP.FeatureFlags.tournaments_only?() do
      conn
      |> redirect(to: ~p"/tournaments")
      |> halt()
    else
      do_home(conn)
    end
  end

  defp do_home(conn) do
    leagues = OP.Leagues.list_leagues_with_preloads(conn.assigns.current_scope)

    seasons =
      Enum.map(leagues, & &1.seasons)
      |> List.flatten()

    # TODO: Need to implement a better way of finding these, a starring system or something.
    seasons = %{
      open: Enum.find(seasons, fn s -> String.contains?(s.slug, "open") end),
      womens: Enum.find(seasons, fn s -> String.contains?(s.slug, "womens") end)
    }

    # TODO :Scope back to upcoming
    tournaments = OP.Tournaments.list_tournaments_with_preloads(conn.assigns.current_scope)

    render(conn, :home,
      leagues: leagues,
      seasons: seasons,
      tournaments: tournaments,
      tournament_submission_enabled?: OP.FeatureFlags.tournament_submission_enabled?()
    )
  end

  def coming_soon(conn, _params) do
    render(conn, :coming_soon)
  end

  def react(conn, _params) do
    render(conn, :react)
  end
end
