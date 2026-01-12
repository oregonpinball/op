defmodule OPWeb.TournamentController do
  use OPWeb, :controller

  def index(conn, _params) do
    tournaments = OP.Tournaments.list_tournaments(conn.assigns.current_scope)

    render(conn, :index, tournaments: tournaments)
  end
end
