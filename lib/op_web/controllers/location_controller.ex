defmodule OPWeb.LocationController do
  use OPWeb, :controller

  alias OP.Locations

  def index(conn, _params) do
    locations = Locations.list_locations(conn.assigns.current_scope)
    render(conn, :index, locations: locations)
  end

  def show(conn, %{"slug" => slug}) do
    location = Locations.get_location_by_slug(conn.assigns.current_scope, slug)

    if is_nil(location) do
      conn
      |> put_status(:not_found)
      |> put_view(OPWeb.ErrorHTML)
      |> render(:"404")
      |> halt()
    else
      tournaments =
        Locations.list_tournaments_at_location(conn.assigns.current_scope, location.id)

      render(conn, :show, location: location, tournaments: tournaments)
    end
  end
end
