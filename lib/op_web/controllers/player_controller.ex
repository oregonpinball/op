defmodule OPWeb.PlayerController do
  use OPWeb, :controller

  def show(conn, %{"slug" => slug}) do
    player = OP.Players.get_player_by_slug(conn.assigns.current_scope, slug)
    render(conn, :show, player: player)
  end
end
