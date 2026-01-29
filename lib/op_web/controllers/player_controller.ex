defmodule OPWeb.PlayerController do
  use OPWeb, :controller

  def show(conn, %{"slug" => slug}) do
    scope = conn.assigns.current_scope
    player = OP.Players.get_player_by_slug!(scope, slug)
    rankings = OP.Leagues.list_rankings_by_player(scope, player.id)
    render(conn, :show, player: player, rankings: rankings)
  end
end
