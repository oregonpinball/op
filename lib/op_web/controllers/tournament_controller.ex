defmodule OPWeb.TournamentController do
  use OPWeb, :controller

  def show(conn, %{"id" => id}) do
    tournament = OP.Tournaments.get_tournament!(conn.assigns.current_scope, id)

    render(conn, :show, tournament: tournament)
  end
end
