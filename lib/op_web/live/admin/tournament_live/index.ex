defmodule OPWeb.Admin.TournamentLive.Index do
  use OPWeb, :live_view

  alias OP.Locations
  alias OP.Tournaments
  alias OP.Tournaments.Tournament

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Tournaments
        <:subtitle>Manage tournaments in the system</:subtitle>
        <:actions>
          <.link navigate={~p"/import"}>
            <.button variant="solid">
              <.icon name="hero-arrow-up-tray" class="mr-1" /> Import from MatchPlay
            </.button>
          </.link>
          <.button patch={~p"/admin/tournaments/new"} color="primary">
            <.icon name="hero-plus" class="mr-1" /> New Tournament
          </.button>
        </:actions>
      </.header>

      <div class="mt-6 bg-white rounded-lg border border-gray-200 p-4">
        <.form
          for={@filter_form}
          id="tournament-filters"
          phx-change="filter"
          phx-submit="filter"
          class="space-y-4"
        >
          <div class="flex gap-4 items-end">
            <div class="flex-1">
              <.input
                field={@filter_form[:search]}
                type="search"
                label="Search tournaments"
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

          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <.input
              field={@filter_form[:location_id]}
              type="select"
              label="Location"
              options={@location_options}
              prompt="All locations"
            />
            <.input
              field={@filter_form[:start_date]}
              type="date"
              label="From date"
            />
            <.input
              field={@filter_form[:end_date]}
              type="date"
              label="To date"
            />
          </div>
        </.form>
      </div>

      <div class="mt-4 flex items-center justify-between text-sm text-gray-500">
        <span>
          <%= if @tournaments_empty? do %>
            No tournaments found
          <% else %>
            Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
              @pagination.page * @pagination.per_page,
              @pagination.total_count
            )} of {@pagination.total_count} tournaments
          <% end %>
        </span>
        <form phx-change="change_per_page">
          <label for="per-page" class="mr-2">Per page:</label>
          <select
            id="per-page"
            name="per_page"
            class="rounded-md border-gray-300 text-sm py-1 pl-2 pr-8"
          >
            <option :for={opt <- [10, 25, 50, 100]} value={opt} selected={opt == @pagination.per_page}>
              {opt}
            </option>
          </select>
        </form>
      </div>

      <div class="mt-4 overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 bg-white border border-gray-200 rounded-lg">
          <thead class="bg-gray-50">
            <tr>
              <.sort_header field="name" label="Name" sort_by={@sort_by} sort_dir={@sort_dir} params={@sort_params} />
              <.sort_header field="start_at" label="Date" sort_by={@sort_by} sort_dir={@sort_dir} params={@sort_params} />
              <.sort_header field="location" label="Location" sort_by={@sort_by} sort_dir={@sort_dir} params={@sort_params} />
              <.sort_header field="status" label="Status" sort_by={@sort_by} sort_dir={@sort_dir} params={@sort_params} />
              <.sort_header field="organizer" label="Organizer" sort_by={@sort_by} sort_dir={@sort_dir} params={@sort_params} />
              <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody id="tournaments" phx-update="stream" class="divide-y divide-gray-200">
            <tr id="empty-tournaments" class="hidden only:table-row">
              <td colspan="6" class="text-center py-8 text-gray-500">
                No tournaments match your filters. Try adjusting your search criteria.
              </td>
            </tr>
            <tr
              :for={{id, tournament} <- @streams.tournaments}
              id={id}
              class="hover:bg-gray-50"
            >
              <td class="px-4 py-3 text-sm">
                <.link
                  navigate={~p"/admin/tournaments/#{tournament}"}
                  class="font-medium text-gray-900 hover:text-blue-600"
                >
                  {tournament.name}
                </.link>
              </td>
              <td class="px-4 py-3 text-sm text-gray-500 whitespace-nowrap">
                {if tournament.start_at, do: Calendar.strftime(tournament.start_at, "%b %d, %Y")}
              </td>
              <td class="px-4 py-3 text-sm text-gray-500">
                {if tournament.location, do: tournament.location.name}
              </td>
              <td class="px-4 py-3 text-sm">
                <span class={[
                  "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium",
                  status_badge_class(tournament.status)
                ]}>
                  {tournament.status}
                </span>
              </td>
              <td class="px-4 py-3 text-sm text-gray-500">
                {if tournament.organizer, do: tournament.organizer.email}
              </td>
              <td class="px-4 py-3 text-sm text-right whitespace-nowrap">
                <.link patch={~p"/admin/tournaments/#{tournament}/edit"}>
                  <.button variant="invisible" size="sm">
                    <.icon name="hero-pencil-square" class="w-4 h-4" />
                  </.button>
                </.link>
                <.button
                  variant="invisible"
                  size="sm"
                  phx-click="delete"
                  phx-value-id={tournament.id}
                  data-confirm="Are you sure you want to delete this tournament?"
                >
                  <.icon name="hero-trash" class="w-4 h-4" />
                </.button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <.pagination
        page={@pagination.page}
        total_pages={@pagination.total_pages}
        path={~p"/admin/tournaments"}
        params={filter_params_for_pagination(@filter_form, @pagination.per_page, @sort_by, @sort_dir)}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="tournament-modal"
        show
        on_cancel={JS.patch(~p"/admin/tournaments")}
      >
        <.live_component
          module={OPWeb.Admin.TournamentLive.Form}
          id={@tournament.id || :new}
          title={@page_title}
          action={@live_action}
          tournament={@tournament}
          current_scope={@current_scope}
          patch={~p"/admin/tournaments"}
        />
      </.modal>
    </Layouts.app>
    """
  end

  attr :field, :string, required: true
  attr :label, :string, required: true
  attr :sort_by, :string, required: true
  attr :sort_dir, :string, required: true
  attr :params, :map, required: true

  defp sort_header(assigns) do
    next_dir = if assigns.field == assigns.sort_by and assigns.sort_dir == "asc", do: "desc", else: "asc"
    params = Map.merge(assigns.params, %{"sort_by" => assigns.field, "sort_dir" => next_dir})
    assigns = assign(assigns, :href_params, params)

    ~H"""
    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
      <.link patch={~p"/admin/tournaments?#{@href_params}"} class="group inline-flex items-center gap-1 hover:text-gray-700">
        {@label}
        <span :if={@field == @sort_by} class="text-gray-400">
          <.icon :if={@sort_dir == "asc"} name="hero-chevron-up" class="w-3 h-3" />
          <.icon :if={@sort_dir == "desc"} name="hero-chevron-down" class="w-3 h-3" />
        </span>
      </.link>
    </th>
    """
  end

  defp status_badge_class(:draft), do: "bg-gray-100 text-gray-800"
  defp status_badge_class(:scheduled), do: "bg-blue-100 text-blue-800"
  defp status_badge_class(:in_progress), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class(:completed), do: "bg-green-100 text-green-800"
  defp status_badge_class(:cancelled), do: "bg-red-100 text-red-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  @impl true
  def mount(_params, _session, socket) do
    locations = Locations.list_locations(socket.assigns.current_scope)
    location_options = Enum.map(locations, &{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:location_options, location_options)
     |> stream(:tournaments, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> apply_filters(params)

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tournament")
    |> assign(
      :tournament,
      Tournaments.get_tournament_with_preloads!(socket.assigns.current_scope, id)
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tournament")
    |> assign(:tournament, %Tournament{standings: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tournaments")
    |> assign(:tournament, nil)
  end

  @allowed_sort_fields ~w(name start_at location status organizer)

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    per_page = parse_per_page(params["per_page"])
    search = params["search"] || ""
    location_id = params["location_id"] || ""
    start_date = params["start_date"] || ""
    end_date = params["end_date"] || ""
    sort_by = parse_sort_by(params["sort_by"])
    sort_dir = parse_sort_dir(params["sort_dir"])

    filter_params = %{
      "search" => search,
      "location_id" => location_id,
      "start_date" => start_date,
      "end_date" => end_date
    }

    {tournaments, pagination} =
      Tournaments.list_tournaments_paginated(
        socket.assigns.current_scope,
        page: page,
        per_page: per_page,
        search: non_empty(search),
        location_id: non_empty(location_id),
        start_date: non_empty(start_date),
        end_date: non_empty(end_date),
        sort_by: String.to_existing_atom(sort_by),
        sort_dir: String.to_existing_atom(sort_dir)
      )

    socket
    |> assign(:filter_form, to_form(filter_params, as: :filters))
    |> assign(:pagination, pagination)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_dir, sort_dir)
    |> assign(:sort_params, sort_params_for_url(filter_params, per_page, sort_by, sort_dir))
    |> assign(:tournaments_empty?, tournaments == [])
    |> stream(:tournaments, tournaments, reset: true)
  end

  defp parse_sort_by(val) when is_binary(val) do
    if val in @allowed_sort_fields, do: val, else: "start_at"
  end

  defp parse_sort_by(_), do: "start_at"

  defp parse_sort_dir("asc"), do: "asc"
  defp parse_sort_dir("desc"), do: "desc"
  defp parse_sort_dir(_), do: "desc"

  defp sort_params_for_url(filter_params, per_page, sort_by, sort_dir) do
    base =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()

    base = if per_page != @default_per_page, do: Map.put(base, "per_page", per_page), else: base
    base = if sort_by != "start_at", do: Map.put(base, "sort_by", sort_by), else: base
    base = if sort_dir != "desc", do: Map.put(base, "sort_dir", sort_dir), else: base
    base
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

  defp current_filter_params(socket) do
    form = socket.assigns.filter_form
    per_page = socket.assigns.pagination.per_page
    sort_by = socket.assigns.sort_by
    sort_dir = socket.assigns.sort_dir

    %{
      search: non_empty(form[:search].value),
      location_id: non_empty(form[:location_id].value),
      start_date: non_empty(form[:start_date].value),
      end_date: non_empty(form[:end_date].value),
      per_page: if(per_page != @default_per_page, do: per_page),
      sort_by: if(sort_by != "start_at", do: sort_by),
      sort_dir: if(sort_dir != "desc", do: sort_dir)
    }
  end

  defp filter_params_for_pagination(filter_form, per_page, sort_by, sort_dir) do
    params = %{
      "search" => filter_form[:search].value,
      "location_id" => filter_form[:location_id].value,
      "start_date" => filter_form[:start_date].value,
      "end_date" => filter_form[:end_date].value
    }

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    params = if sort_by != "start_at", do: Map.put(params, "sort_by", sort_by), else: params
    params = if sort_dir != "desc", do: Map.put(params, "sort_dir", sort_dir), else: params

    params
    |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
    |> Map.new()
  end

  @impl true
  def handle_info({OPWeb.Admin.TournamentLive.Form, {:saved, tournament}}, socket) do
    _tournament =
      Tournaments.get_tournament_with_preloads!(socket.assigns.current_scope, tournament.id)

    params = current_filter_params(socket)

    {tournaments, pagination} =
      Tournaments.list_tournaments_paginated(
        socket.assigns.current_scope,
        page: socket.assigns.pagination.page,
        per_page: socket.assigns.pagination.per_page,
        search: params.search,
        location_id: params.location_id,
        start_date: params.start_date,
        end_date: params.end_date,
        sort_by: sort_by_atom(params),
        sort_dir: sort_dir_atom(params)
      )

    {:noreply,
     socket
     |> assign(:pagination, pagination)
     |> assign(:tournaments_empty?, tournaments == [])
     |> stream(:tournaments, tournaments, reset: true)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    per_page = socket.assigns.pagination.per_page
    sort_by = socket.assigns.sort_by
    sort_dir = socket.assigns.sort_dir

    params =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()
      |> Map.put("page", "1")

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    params = if sort_by != "start_at", do: Map.put(params, "sort_by", sort_by), else: params
    params = if sort_dir != "desc", do: Map.put(params, "sort_dir", sort_dir), else: params

    {:noreply, push_patch(socket, to: ~p"/admin/tournaments?#{params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    params =
      socket.assigns.filter_form
      |> filter_params_for_pagination(parse_per_page(per_page), socket.assigns.sort_by, socket.assigns.sort_dir)
      |> Map.put("page", "1")
      |> Map.put("per_page", per_page)

    {:noreply, push_patch(socket, to: ~p"/admin/tournaments?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/tournaments")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    tournament = Tournaments.get_tournament!(socket.assigns.current_scope, id)
    {:ok, _} = Tournaments.delete_tournament(socket.assigns.current_scope, tournament)

    params = current_filter_params(socket)

    {tournaments, pagination} =
      Tournaments.list_tournaments_paginated(
        socket.assigns.current_scope,
        page: socket.assigns.pagination.page,
        per_page: socket.assigns.pagination.per_page,
        search: params.search,
        location_id: params.location_id,
        start_date: params.start_date,
        end_date: params.end_date,
        sort_by: sort_by_atom(params),
        sort_dir: sort_dir_atom(params)
      )

    socket =
      if tournaments == [] and pagination.page > 1 do
        params =
          socket.assigns.filter_form
          |> filter_params_for_pagination(socket.assigns.pagination.per_page, socket.assigns.sort_by, socket.assigns.sort_dir)
          |> Map.put("page", pagination.page - 1)

        push_patch(socket, to: ~p"/admin/tournaments?#{params}")
      else
        socket
        |> assign(:pagination, pagination)
        |> assign(:tournaments_empty?, tournaments == [])
        |> stream(:tournaments, tournaments, reset: true)
      end

    {:noreply, socket}
  end

  defp sort_by_atom(%{sort_by: nil}), do: :start_at
  defp sort_by_atom(%{sort_by: val}) when is_binary(val), do: String.to_existing_atom(val)
  defp sort_by_atom(_), do: :start_at

  defp sort_dir_atom(%{sort_dir: nil}), do: :desc
  defp sort_dir_atom(%{sort_dir: val}) when is_binary(val), do: String.to_existing_atom(val)
  defp sort_dir_atom(_), do: :desc
end
