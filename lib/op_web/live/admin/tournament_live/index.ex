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

      <div id="tournaments" phx-update="stream" class="mt-4 space-y-4">
        <div id="empty-tournaments" class="hidden only:block text-center py-8 text-gray-500">
          No tournaments match your filters. Try adjusting your search criteria.
        </div>
        <div
          :for={{id, tournament} <- @streams.tournaments}
          id={id}
          class="flex items-center justify-between p-4 bg-white rounded-lg border border-gray-200"
        >
          <div class="flex-1">
            <.link
              navigate={~p"/admin/tournaments/#{tournament}"}
              class="text-lg font-semibold text-gray-900 hover:text-blue-600"
            >
              {tournament.name}
            </.link>
            <div class="text-sm text-gray-500 mt-1">
              <span :if={tournament.start_at}>
                {Calendar.strftime(tournament.start_at, "%B %d, %Y at %I:%M %p")}
              </span>
              <span :if={tournament.season} class="ml-4">
                Season: {tournament.season.name}
              </span>
              <span :if={tournament.location} class="ml-4">
                Location: {tournament.location.name}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <.link patch={~p"/admin/tournaments/#{tournament}/edit"}>
              <.button variant="invisible">Edit</.button>
            </.link>
            <.button
              variant="invisible"
              phx-click="delete"
              phx-value-id={tournament.id}
              data-confirm="Are you sure you want to delete this tournament?"
            >
              Delete
            </.button>
          </div>
        </div>
      </div>

      <.pagination
        page={@pagination.page}
        total_pages={@pagination.total_pages}
        path={~p"/admin/tournaments"}
        params={filter_params_for_pagination(@filter_form, @pagination.per_page)}
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

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    per_page = parse_per_page(params["per_page"])
    search = params["search"] || ""
    location_id = params["location_id"] || ""
    start_date = params["start_date"] || ""
    end_date = params["end_date"] || ""

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
        end_date: non_empty(end_date)
      )

    socket
    |> assign(:filter_form, to_form(filter_params, as: :filters))
    |> assign(:pagination, pagination)
    |> assign(:tournaments_empty?, tournaments == [])
    |> stream(:tournaments, tournaments, reset: true)
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

    %{
      search: non_empty(form[:search].value),
      location_id: non_empty(form[:location_id].value),
      start_date: non_empty(form[:start_date].value),
      end_date: non_empty(form[:end_date].value),
      per_page: if(per_page != @default_per_page, do: per_page)
    }
  end

  defp filter_params_for_pagination(filter_form, per_page) do
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
        end_date: params.end_date
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

    params =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()
      |> Map.put("page", "1")

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    {:noreply, push_patch(socket, to: ~p"/admin/tournaments?#{params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    params =
      socket.assigns.filter_form
      |> filter_params_for_pagination(parse_per_page(per_page))
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
        end_date: params.end_date
      )

    socket =
      if tournaments == [] and pagination.page > 1 do
        params =
          socket.assigns.filter_form
          |> filter_params_for_pagination(socket.assigns.pagination.per_page)
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
end
