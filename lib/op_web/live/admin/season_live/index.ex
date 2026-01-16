defmodule OPWeb.Admin.SeasonLive.Index do
  use OPWeb, :live_view

  alias OP.Leagues
  alias OP.Leagues.Season

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Seasons
        <:subtitle>Manage seasons in the system</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/seasons/new"} color="primary">
            <.icon name="hero-plus" class="mr-1" /> New Season
          </.button>
        </:actions>
      </.header>

      <div class="mt-6 bg-white rounded-lg border border-gray-200 p-4">
        <.form
          for={@filter_form}
          id="season-filters"
          phx-change="filter"
          phx-submit="filter"
          class="space-y-4"
        >
          <div class="flex gap-4 items-end">
            <div class="flex-1">
              <.input
                field={@filter_form[:search]}
                type="search"
                label="Search seasons"
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
              field={@filter_form[:league_id]}
              type="select"
              label="League"
              options={@league_options}
              prompt="All leagues"
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
          <%= if @seasons_empty? do %>
            No seasons found
          <% else %>
            Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
              @pagination.page * @pagination.per_page,
              @pagination.total_count
            )} of {@pagination.total_count} seasons
          <% end %>
        </span>
      </div>

      <div id="seasons" phx-update="stream" class="mt-4 space-y-4">
        <div id="empty-seasons" class="hidden only:block text-center py-8 text-gray-500">
          No seasons match your filters. Try adjusting your search criteria.
        </div>
        <div
          :for={{id, season} <- @streams.seasons}
          id={id}
          class="flex items-center justify-between p-4 bg-white rounded-lg border border-gray-200"
        >
          <div class="flex-1">
            <.link
              navigate={~p"/admin/seasons/#{season}"}
              class="text-lg font-semibold text-gray-900 hover:text-blue-600"
            >
              {season.name}
            </.link>
            <div class="text-sm text-gray-500 mt-1">
              <span :if={season.start_at}>
                {Calendar.strftime(season.start_at, "%B %d, %Y")}
              </span>
              <span :if={season.end_at}>
                - {Calendar.strftime(season.end_at, "%B %d, %Y")}
              </span>
              <span :if={season.league} class="ml-4">
                League: {season.league.name}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <.link navigate={~p"/admin/seasons/#{season}/edit"}>
              <.button variant="invisible">Edit</.button>
            </.link>
            <.button
              variant="invisible"
              phx-click="delete"
              phx-value-id={season.id}
              data-confirm="Are you sure you want to delete this season?"
            >
              Delete
            </.button>
          </div>
        </div>
      </div>

      <.pagination
        page={@pagination.page}
        total_pages={@pagination.total_pages}
        path={~p"/admin/seasons"}
        params={filter_params_for_pagination(@filter_form)}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    leagues = Leagues.list_leagues(socket.assigns.current_scope)
    league_options = Enum.map(leagues, &{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:league_options, league_options)
     |> stream(:seasons, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_filters(socket, params)}
  end

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    search = params["search"] || ""
    league_id = params["league_id"] || ""
    start_date = params["start_date"] || ""
    end_date = params["end_date"] || ""

    filter_params = %{
      "search" => search,
      "league_id" => league_id,
      "start_date" => start_date,
      "end_date" => end_date
    }

    seasons = list_seasons_filtered(socket.assigns.current_scope, search, league_id, start_date, end_date)
    total_count = length(seasons)
    per_page = @default_per_page
    total_pages = max(ceil(total_count / per_page), 1)
    offset = (page - 1) * per_page

    paginated_seasons = seasons |> Enum.drop(offset) |> Enum.take(per_page)

    pagination = %{
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }

    socket
    |> assign(:filter_form, to_form(filter_params, as: :filters))
    |> assign(:pagination, pagination)
    |> assign(:seasons_empty?, paginated_seasons == [])
    |> stream(:seasons, paginated_seasons, reset: true)
  end

  defp list_seasons_filtered(scope, search, league_id, start_date, end_date) do
    seasons = Leagues.list_seasons_with_preloads(scope)

    seasons =
      if search != "" do
        search_lower = String.downcase(search)

        Enum.filter(seasons, fn season ->
          String.contains?(String.downcase(season.name), search_lower) ||
            (season.slug && String.contains?(String.downcase(season.slug), search_lower))
        end)
      else
        seasons
      end

    seasons =
      if league_id != "" do
        league_id_int = String.to_integer(league_id)
        Enum.filter(seasons, fn season -> season.league_id == league_id_int end)
      else
        seasons
      end

    seasons =
      if start_date != "" do
        case Date.from_iso8601(start_date) do
          {:ok, start_date_parsed} ->
            start_datetime = DateTime.new!(start_date_parsed, ~T[00:00:00])

            Enum.filter(seasons, fn season ->
              season.start_at && DateTime.compare(season.start_at, start_datetime) != :lt
            end)

          _ ->
            seasons
        end
      else
        seasons
      end

    seasons =
      if end_date != "" do
        case Date.from_iso8601(end_date) do
          {:ok, end_date_parsed} ->
            end_datetime = DateTime.new!(end_date_parsed, ~T[23:59:59])

            Enum.filter(seasons, fn season ->
              season.end_at && DateTime.compare(season.end_at, end_datetime) != :gt
            end)

          _ ->
            seasons
        end
      else
        seasons
      end

    seasons
  end

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {num, _} when num > 0 -> num
      _ -> 1
    end
  end

  defp filter_params_for_pagination(filter_form) do
    %{
      "search" => filter_form[:search].value,
      "league_id" => filter_form[:league_id].value,
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

    {:noreply, push_patch(socket, to: ~p"/admin/seasons?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/seasons")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    season = Leagues.get_season!(socket.assigns.current_scope, id)
    {:ok, _} = Leagues.delete_season(socket.assigns.current_scope, season)

    search = socket.assigns.filter_form[:search].value || ""
    league_id = socket.assigns.filter_form[:league_id].value || ""
    start_date = socket.assigns.filter_form[:start_date].value || ""
    end_date = socket.assigns.filter_form[:end_date].value || ""

    seasons = list_seasons_filtered(socket.assigns.current_scope, search, league_id, start_date, end_date)
    total_count = length(seasons)
    per_page = @default_per_page
    total_pages = max(ceil(total_count / per_page), 1)
    page = socket.assigns.pagination.page
    offset = (page - 1) * per_page

    paginated_seasons = seasons |> Enum.drop(offset) |> Enum.take(per_page)

    pagination = %{
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }

    socket =
      if paginated_seasons == [] and page > 1 do
        params =
          socket.assigns.filter_form
          |> filter_params_for_pagination()
          |> Map.put("page", page - 1)

        push_patch(socket, to: ~p"/admin/seasons?#{params}")
      else
        socket
        |> assign(:pagination, pagination)
        |> assign(:seasons_empty?, paginated_seasons == [])
        |> stream(:seasons, paginated_seasons, reset: true)
      end

    {:noreply, socket}
  end
end
