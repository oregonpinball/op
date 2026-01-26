defmodule OPWeb.TournamentLive.Index do
  use OPWeb, :live_view

  alias OP.Leagues
  alias OP.Locations
  alias OP.Tournaments

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <.sheet id="filters-advanced" class="max-w-96" phx-update="ignore">
      <h1 class="text-3xl font-semibold">Advanced filters</h1>

      <div class="mt-4 bg-white rounded border p-4">
        <.form
          for={@filter_form}
          id="tournament-filters-adv"
          phx-change="filter"
          phx-submit="filter"
          class="space-y-4"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="md:col-span-2">
              <.input
                field={@filter_form[:search]}
                type="search"
                label="Search tournaments"
                placeholder="Search by name..."
                phx-debounce="300"
              />
            </div>

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

          <div class="flex gap-4 items-end">
            <div class="flex-1"></div>
            <.button
              type="button"
              variant="invisible"
              phx-click="clear_filters"
              class="flex items-center"
            >
              <.icon name="hero-x-mark" class="w-4 h-4 mr-1" />
              <span>Clear</span>
            </.button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4"></div>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4"></div>
        </.form>
      </div>
    </.sheet>

    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="h-full bg-[url('/images/mt-hood.svg')] bg-position-[34%_95%] bg-no-repeat">
        <div class="container mx-auto p-4">
          <h1 class="text-7xl font-bold">Events</h1>
          <h2 class="text-3xl font-medium mt-2">
            Oregon Pinball tournaments, competitions, and more
          </h2>

          <div class="">
            <.form
              for={@filter_form}
              id="tournament-filters"
              phx-change="filter"
              phx-submit="filter"
              class=""
            >
              <div class="flex flex-col mt-4">
                <div class="grid grid-cols-5 gap-4">
                  <div class="col-span-3">
                    <div class="flex items-center space-x-2">
                      <div class="grow">
                        <.input
                          field={@filter_form[:search]}
                          type="search"
                          label="Search tournaments"
                          placeholder="Search by name..."
                          phx-debounce="300"
                        />
                      </div>
                    </div>
                  </div>

                  <div class="col-span-2">
                    <.input
                      field={@filter_form[:status]}
                      type="select"
                      label="When?"
                      options={@status_options}
                      prompt="All (past or upcoming)"
                    />
                  </div>
                </div>
              </div>
            </.form>
          </div>

          <div class="mt-4 bg-white rounded md:bg-transparent p-2 flex items-center justify-between">
            <div class="grow">
              <%= if @tournaments_empty? do %>
                No tournaments found
              <% else %>
                Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
                  @pagination.page * @pagination.per_page,
                  @pagination.total_count
                )} of {@pagination.total_count} tournaments
              <% end %>
            </div>

            <div class="flex items-center space-x-2">
              <.button
                phx-click={toggle("#filters-advanced")}
                type="button"
                variant="invisible"
                class="flex items-center space-x-0.5"
              >
                <.icon name="hero-funnel" class="w-4 h-4" />
                <span class="hidden md:inline">Advanced Filters</span>
              </.button>
              <.button
                type="button"
                color="secondary"
                phx-click="clear_filters"
                class="flex items-center space-x-0.5"
              >
                <.icon name="hero-x-mark" class="w-4 h-4 mr-1" />
                <span>Clear</span>
              </.button>
            </div>
          </div>

          <div id="tournaments" phx-update="stream" class="mt-4 space-y-4">
            <div id="empty-tournaments" class="hidden only:block text-center py-8 text-gray-500">
              No tournaments match your filters. Try adjusting your search criteria.
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4" id="tournaments-wrapper">
              <div
                :for={{id, tournament} <- @streams.tournaments}
                id={id}
                class=""
              >
                <OPWeb.Tournaments.card tournament={tournament} />
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
