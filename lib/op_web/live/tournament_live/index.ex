defmodule OPWeb.TournamentLive.Index do
  use OPWeb, :live_view

  alias OP.Leagues
  alias OP.Locations
  alias OP.Tournaments

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto">
        <.header>
          Tournaments
          <:subtitle>Browse all pinball tournaments</:subtitle>
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

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <.input
                field={@filter_form[:league_id]}
                type="select"
                label="League"
                options={@league_options}
                prompt="All leagues"
              />
              <.input
                field={@filter_form[:season_id]}
                type="select"
                label="Season"
                options={@season_options}
                prompt="All seasons"
              />
              <.input
                field={@filter_form[:location_id]}
                type="select"
                label="Location"
                options={@location_options}
                prompt="All locations"
              />
              <.input
                field={@filter_form[:status]}
                type="select"
                label="Status"
                options={@status_options}
                prompt="All"
              />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
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
                navigate={~p"/tournaments/#{tournament.slug}"}
                class="text-lg font-semibold text-gray-900 hover:text-emerald-700"
              >
                {tournament.name}
              </.link>
              <div class="text-sm text-gray-500 mt-1 flex flex-wrap gap-x-4">
                <span :if={tournament.start_at}>
                  {Calendar.strftime(tournament.start_at, "%B %d, %Y")}
                </span>
                <span :if={tournament.location}>
                  {tournament.location.name}
                </span>
                <span :if={tournament.season}>
                  {tournament.season.name}
                </span>
                <span :if={tournament.season && tournament.season.league}>
                  {tournament.season.league.name}
                </span>
              </div>
            </div>
            <div class="ml-4">
              <%= if tournament.start_at && DateTime.compare(tournament.start_at, DateTime.utc_now()) == :gt do %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  Upcoming
                </span>
              <% else %>
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                  Past
                </span>
              <% end %>
            </div>
          </div>
        </div>

        <.pagination
          page={@pagination.page}
          total_pages={@pagination.total_pages}
          path={~p"/tournaments"}
          params={filter_params_for_pagination(@filter_form)}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    locations = Locations.list_locations(socket.assigns.current_scope)
    location_options = Enum.map(locations, &{&1.name, &1.id})

    leagues = Leagues.list_leagues(socket.assigns.current_scope)
    league_options = Enum.map(leagues, &{&1.name, &1.id})

    seasons = Leagues.list_seasons_with_preloads(socket.assigns.current_scope)

    season_options =
      Enum.map(seasons, fn season ->
        league_name = if season.league, do: "#{season.league.name} - ", else: ""
        {"#{league_name}#{season.name}", season.id}
      end)

    status_options = [{"Upcoming", "upcoming"}, {"Past", "past"}]

    {:ok,
     socket
     |> assign(:location_options, location_options)
     |> assign(:league_options, league_options)
     |> assign(:season_options, season_options)
     |> assign(:status_options, status_options)
     |> stream(:tournaments, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket = apply_filters(socket, params)
    {:noreply, socket}
  end

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    search = params["search"] || ""
    location_id = params["location_id"] || ""
    season_id = params["season_id"] || ""
    league_id = params["league_id"] || ""
    status = params["status"] || ""
    start_date = params["start_date"] || ""
    end_date = params["end_date"] || ""

    filter_params = %{
      "search" => search,
      "location_id" => location_id,
      "season_id" => season_id,
      "league_id" => league_id,
      "status" => status,
      "start_date" => start_date,
      "end_date" => end_date
    }

    {tournaments, pagination} =
      Tournaments.list_tournaments_paginated(
        socket.assigns.current_scope,
        page: page,
        per_page: @default_per_page,
        search: non_empty(search),
        location_id: non_empty(location_id),
        season_id: non_empty(season_id),
        league_id: non_empty(league_id),
        status: non_empty(status),
        start_date: non_empty(start_date),
        end_date: non_empty(end_date)
      )

    socket
    |> assign(:page_title, "Tournaments")
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

  defp non_empty(""), do: nil
  defp non_empty(value), do: value

  defp filter_params_for_pagination(filter_form) do
    %{
      "search" => filter_form[:search].value,
      "location_id" => filter_form[:location_id].value,
      "season_id" => filter_form[:season_id].value,
      "league_id" => filter_form[:league_id].value,
      "status" => filter_form[:status].value,
      "start_date" => filter_form[:start_date].value,
      "end_date" => filter_form[:end_date].value
    }
    |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
    |> Map.new()
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    params =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()
      |> Map.put("page", "1")

    {:noreply, push_patch(socket, to: ~p"/tournaments?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/tournaments")}
  end
end
