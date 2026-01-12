defmodule OPWeb.LeagueController do
  use OPWeb, :controller

  def show(conn, %{"slug" => slug}) do
    league = OP.Leagues.get_league_by_slug(conn.assigns.current_scope, slug)

    render(conn, :show, league: league)
  end
end
