defmodule OPWeb.PageController do
  use OPWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
