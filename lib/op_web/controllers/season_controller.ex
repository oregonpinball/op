defmodule OPWeb.SeasonController do
  use OPWeb, :controller

  def show(conn, %{"slug" => slug}) do
    season = OP.Leagues.get_season_by_slug(conn.assigns.current_scope, slug)

    if is_nil(season) do
      conn
      |> put_status(:not_found)
      |> put_view(OPWeb.ErrorHTML)
      |> render(:"404")
      |> halt()
    else
      rankings =
        OP.Leagues.list_rankings_by_season_sorted(conn.assigns.current_scope, season.id)

      render(conn, :show, season: season, rankings: rankings)
    end
  end
end
