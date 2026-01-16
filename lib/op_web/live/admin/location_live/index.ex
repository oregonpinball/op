defmodule OPWeb.Admin.LocationLive.Index do
  use OPWeb, :live_view

  alias OP.Locations

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Manage Locations
        <:actions>
          <.button navigate={~p"/admin/locations/new"} color="primary">
            <.icon name="hero-plus" class="mr-1" /> New Location
          </.button>
        </:actions>
      </.header>

      <div class="mt-6">
        <.table id="locations" rows={@streams.locations}>
          <:col :let={{_id, location}} label="Name">{location.name}</:col>
          <:col :let={{_id, location}} label="City">{location.city}</:col>
          <:col :let={{_id, location}} label="State">{location.state}</:col>
          <:action :let={{_id, location}}>
            <.link navigate={~p"/admin/locations/#{location.slug}/edit"}>
              <.button size="sm" variant="invisible">Edit</.button>
            </.link>
          </:action>
          <:action :let={{_id, location}}>
            <.button
              size="sm"
              color="error"
              variant="invisible"
              phx-click={JS.push("delete", value: %{id: location.id})}
              data-confirm="Are you sure you want to delete this location?"
            >
              Delete
            </.button>
          </:action>
        </.table>
        <div :if={@locations_empty?} class="text-center text-base-content/70 py-8">
          No locations found. Create your first location to get started.
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    locations = Locations.list_locations(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:locations_empty?, locations == [])
     |> stream(:locations, locations)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    location = Locations.get_location!(socket.assigns.current_scope, id)
    {:ok, _} = Locations.delete_location(socket.assigns.current_scope, location)

    locations = Locations.list_locations(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:locations_empty?, locations == [])
     |> stream_delete(:locations, location)}
  end
end
