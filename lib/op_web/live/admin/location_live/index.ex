defmodule OPWeb.Admin.LocationLive.Index do
  use OPWeb, :live_view

  alias OP.Locations

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          Manage Locations
          <:actions>
            <.button navigate={~p"/admin/locations/new"} color="primary">
              <.icon name="hero-plus" class="mr-1" /> New Location
            </.button>
          </:actions>
        </.header>

        <div class="mt-6 bg-white rounded-lg border border-gray-200 p-4">
          <.form
            for={@filter_form}
            id="location-filters"
            phx-change="filter"
            phx-submit="filter"
            class="space-y-4"
          >
            <div class="flex gap-4 items-end">
              <div class="flex-1">
                <.input
                  field={@filter_form[:search]}
                  type="search"
                  label="Search locations"
                  placeholder="Search by name..."
                  phx-debounce="300"
                />
              </div>
              <.button
                type="button"
                variant="invisible"
                phx-click="clear_filters"
                class="mb-2"
              >
                <.icon name="hero-x-mark" class="w-4 h-4 mr-1" /> Clear
              </.button>
            </div>
          </.form>
        </div>

        <div class="mt-4 flex items-center justify-between text-sm text-gray-500">
          <span>
            <%= if @locations_empty? do %>
              No locations found
            <% else %>
              Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
                @pagination.page * @pagination.per_page,
                @pagination.total_count
              )} of {@pagination.total_count} locations
            <% end %>
          </span>
          <form phx-change="change_per_page">
            <label for="per-page" class="mr-2">Per page:</label>
            <select
              id="per-page"
              name="per_page"
              class="rounded-md border-gray-300 text-sm py-1 pl-2 pr-8"
            >
              <option
                :for={opt <- [10, 25, 50, 100]}
                value={opt}
                selected={opt == @pagination.per_page}
              >
                {opt}
              </option>
            </select>
          </form>
        </div>

        <div class="mt-4">
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
            No locations found. Try adjusting your search criteria.
          </div>
        </div>

        <.pagination
          page={@pagination.page}
          total_pages={@pagination.total_pages}
          path={~p"/admin/locations"}
          params={filter_params_for_pagination(@filter_form, @pagination.per_page)}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :locations, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_filters(socket, params)}
  end

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    per_page = parse_per_page(params["per_page"])
    search = params["search"] || ""

    filter_params = %{"search" => search}

    {locations, pagination} =
      Locations.list_locations_paginated(
        socket.assigns.current_scope,
        page: page,
        per_page: per_page,
        search: non_empty(search)
      )

    socket
    |> assign(:filter_form, to_form(filter_params, as: :filters))
    |> assign(:pagination, pagination)
    |> assign(:locations_empty?, locations == [])
    |> stream(:locations, locations, reset: true)
  end

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {num, _} when num > 0 -> num
      _ -> 1
    end
  end

  @allowed_per_page [10, 25, 50, 100]

  defp parse_per_page(nil), do: @default_per_page

  defp parse_per_page(value) when is_binary(value) do
    case Integer.parse(value) do
      {num, _} when num in @allowed_per_page -> num
      _ -> @default_per_page
    end
  end

  defp non_empty(""), do: nil
  defp non_empty(value), do: value

  defp filter_params_for_pagination(filter_form, per_page) do
    params =
      %{"search" => filter_form[:search].value}
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()

    if per_page != @default_per_page, do: Map.put(params, "per_page", per_page), else: params
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    per_page = socket.assigns.pagination.per_page

    params =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()
      |> Map.put("page", "1")

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    {:noreply, push_patch(socket, to: ~p"/admin/locations?#{params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    params =
      filter_params_for_pagination(socket.assigns.filter_form, parse_per_page(per_page))
      |> Map.put("page", "1")
      |> Map.put("per_page", per_page)

    {:noreply, push_patch(socket, to: ~p"/admin/locations?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/locations")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    location = Locations.get_location!(socket.assigns.current_scope, id)
    {:ok, _} = Locations.delete_location(socket.assigns.current_scope, location)

    {locations, pagination} =
      Locations.list_locations_paginated(
        socket.assigns.current_scope,
        page: socket.assigns.pagination.page,
        per_page: socket.assigns.pagination.per_page,
        search: non_empty(socket.assigns.filter_form[:search].value)
      )

    socket =
      if locations == [] and pagination.page > 1 do
        params =
          filter_params_for_pagination(socket.assigns.filter_form, socket.assigns.pagination.per_page)
          |> Map.put("page", pagination.page - 1)

        push_patch(socket, to: ~p"/admin/locations?#{params}")
      else
        socket
        |> assign(:pagination, pagination)
        |> assign(:locations_empty?, locations == [])
        |> stream(:locations, locations, reset: true)
      end

    {:noreply, socket}
  end
end
