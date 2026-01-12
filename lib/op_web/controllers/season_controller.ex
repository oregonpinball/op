defmodule OPWeb.SeasonController do
  use OPWeb, :controller

  def show(conn, %{"slug" => slug}) do
    season = OP.Leagues.get_season_by_slug(conn.assigns.current_scope, slug)

    render(conn, :show, season: season)
  end
end
