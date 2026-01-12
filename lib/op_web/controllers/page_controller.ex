defmodule OPWeb.PageController do
  use OPWeb, :controller

  def home(conn, _params) do
    leagues = OP.Leagues.list_leagues_with_preloads(conn.assigns.current_scope)
    render(conn, :home, leagues: leagues)
  end

  def react(conn, _params) do
    render(conn, :react)
  end
end
