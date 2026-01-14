defmodule OPWeb.LocationLive.Form do
  use OPWeb, :live_view

  alias OP.Locations
  alias OP.Locations.Location

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>
          <%= if @live_action == :new do %>
            Add a new pinball location
          <% else %>
            Update location details
          <% end %>
        </:subtitle>
      </.header>

      <div class="mt-6 max-w-2xl">
        <.form for={@form} id="location-form" phx-change="validate" phx-submit="save">
          <.input field={@form[:name]} type="text" label="Name" required />

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <.input field={@form[:address]} type="text" label="Address" />
            <.input field={@form[:address_2]} type="text" label="Address 2" />
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <.input field={@form[:city]} type="text" label="City" />
            <.input field={@form[:state]} type="text" label="State" />
            <.input field={@form[:postal_code]} type="text" label="Postal Code" />
            <.input field={@form[:country]} type="text" label="Country" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:latitude]} type="number" label="Latitude" step="any" />
            <.input field={@form[:longitude]} type="number" label="Longitude" step="any" />
          </div>

          <.input field={@form[:external_id]} type="text" label="External ID" />

          <div class="mt-6 flex gap-4">
            <.button type="submit" color="primary" phx-disable-with="Saving...">
              Save Location
            </.button>
            <.button navigate={~p"/admin/locations"} variant="invisible">
              Cancel
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    location = %Location{}

    socket
    |> assign(:page_title, "New Location")
    |> assign(:location, location)
    |> assign(:form, to_form(Locations.change_location(location)))
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    location = Locations.get_location_by_slug(socket.assigns.current_scope, slug)

    socket
    |> assign(:page_title, "Edit Location")
    |> assign(:location, location)
    |> assign(:form, to_form(Locations.change_location(location)))
  end

  @impl true
  def handle_event("validate", %{"location" => location_params}, socket) do
    changeset =
      socket.assigns.location
      |> Locations.change_location(location_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"location" => location_params}, socket) do
    save_location(socket, socket.assigns.live_action, location_params)
  end

  defp save_location(socket, :edit, location_params) do
    case Locations.update_location(
           socket.assigns.current_scope,
           socket.assigns.location,
           location_params
         ) do
      {:ok, _location} ->
        {:noreply,
         socket
         |> put_flash(:info, "Location updated successfully")
         |> push_navigate(to: ~p"/admin/locations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_location(socket, :new, location_params) do
    case Locations.create_location(socket.assigns.current_scope, location_params) do
      {:ok, _location} ->
        {:noreply,
         socket
         |> put_flash(:info, "Location created successfully")
         |> push_navigate(to: ~p"/admin/locations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
