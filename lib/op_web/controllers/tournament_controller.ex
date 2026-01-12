defmodule OPWeb.TournamentController do
  use OPWeb, :controller

  def index(conn, _params) do
    tournaments = OP.Tournaments.list_tournaments(conn.assigns.current_scope)

    render(conn, :index, tournaments: tournaments)
  end

  def show(conn, %{"id" => id}) do
    tournament = OP.Tournaments.get_tournament!(conn.assigns.current_scope, id)

    render(conn, :show, tournament: tournament)
  end
end
