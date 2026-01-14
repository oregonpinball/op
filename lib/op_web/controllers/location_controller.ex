defmodule OPWeb.LocationController do
  use OPWeb, :controller

  alias OP.Locations

  def index(conn, _params) do
    locations = Locations.list_locations(conn.assigns.current_scope)
    render(conn, :index, locations: locations)
  end

  def show(conn, %{"slug" => slug}) do
    location = Locations.get_location_by_slug(conn.assigns.current_scope, slug)
    render(conn, :show, location: location)
  end
end
