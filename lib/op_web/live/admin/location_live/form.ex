defmodule OPWeb.Admin.LocationLive.Form do
  use OPWeb, :live_view

  alias OP.Locations
  alias OP.Locations.Location

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
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
            <.input
              field={@form[:pinball_map_id]}
              type="number"
              label="Pinball Map ID"
            />

            <%!-- Banner Image Upload Section --%>
            <div class="mt-6">
              <label class="block text-sm font-semibold leading-6 text-zinc-800 mb-2">
                Banner Image
              </label>

              <%!-- Show current banner if exists --%>
              <div :if={@location.banner_image} class="mb-4">
                <p class="text-sm text-zinc-600 mb-2">Current banner:</p>
                <div class="relative inline-block">
                  <img
                    src={"/uploads/#{@location.banner_image}"}
                    alt="Banner preview"
                    class="max-w-md rounded-lg border border-zinc-300 shadow-sm"
                  />
                  <button
                    type="button"
                    phx-click="delete_banner"
                    class="absolute top-2 right-2 bg-red-600 hover:bg-red-700 text-white rounded-full p-2 shadow-lg transition-colors"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
              </div>

              <%!-- Upload input --%>
              <div :if={!@location.banner_image || @uploads.banner_image.entries != []}>
                <div class="mt-2">
                  <.live_file_input upload={@uploads.banner_image} class="block w-full text-sm text-zinc-900 border border-zinc-300 rounded-lg cursor-pointer bg-zinc-50 focus:outline-none" />
                  <p class="mt-1 text-sm text-zinc-500">
                    Accepted formats: JPG, PNG, GIF, WebP (max 5 MB)
                  </p>
                </div>

                <%!-- Upload preview --%>
                <div :for={entry <- @uploads.banner_image.entries} class="mt-4">
                  <div class="relative inline-block">
                    <.live_img_preview entry={entry} class="max-w-md rounded-lg border border-zinc-300 shadow-sm" />
                    <button
                      type="button"
                      phx-click="cancel_upload"
                      phx-value-ref={entry.ref}
                      class="absolute top-2 right-2 bg-red-600 hover:bg-red-700 text-white rounded-full p-2 shadow-lg transition-colors"
                    >
                      <.icon name="hero-x-mark" class="w-4 h-4" />
                    </button>
                  </div>

                  <%!-- Upload errors --%>
                  <div :for={err <- upload_errors(@uploads.banner_image, entry)} class="mt-2">
                    <p class="text-sm text-red-600">{error_to_string(err)}</p>
                  </div>
                </div>
              </div>
            </div>

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
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> allow_upload(:banner_image,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_entries: 1,
        max_file_size: 5_000_000
      )

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

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :banner_image, ref)}
  end

  def handle_event("delete_banner", _params, socket) do
    location = socket.assigns.location

    # Delete the physical file if it exists
    if location.banner_image do
      file_path = Path.join(["priv", "static", "uploads", location.banner_image])
      File.rm(file_path)
    end

    # Update the location record
    case Locations.update_location(
           socket.assigns.current_scope,
           location,
           %{banner_image: nil}
         ) do
      {:ok, updated_location} ->
        {:noreply,
         socket
         |> assign(:location, updated_location)
         |> put_flash(:info, "Banner image deleted successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete banner image")}
    end
  end

  def handle_event("save", %{"location" => location_params}, socket) do
    save_location(socket, socket.assigns.live_action, location_params)
  end

  defp save_location(socket, :edit, location_params) do
    location_params = consume_uploaded_banner(socket, location_params)

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
    location_params = consume_uploaded_banner(socket, location_params)

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

  defp consume_uploaded_banner(socket, location_params) do
    uploaded_files =
      consume_uploaded_entries(socket, :banner_image, fn %{path: path}, entry ->
        # Generate a unique filename
        filename = "#{Nanoid.generate()}-#{entry.client_name}"

        # Ensure upload directory exists
        upload_dir = Path.join(["priv", "static", "uploads"])
        File.mkdir_p!(upload_dir)

        # Copy file to destination
        dest = Path.join(upload_dir, filename)
        File.cp!(path, dest)

        {:ok, filename}
      end)

    case uploaded_files do
      [filename] -> Map.put(location_params, "banner_image", filename)
      [] -> location_params
    end
  end

  defp error_to_string(:too_large), do: "File is too large (max 5 MB)"
  defp error_to_string(:not_accepted), do: "File type not accepted"
  defp error_to_string(:too_many_files), do: "Too many files (max 1)"
end
