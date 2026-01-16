defmodule OPWeb.Admin.LeagueLive.Index do
  use OPWeb, :live_view

  alias OP.Leagues

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Leagues
        <:subtitle>Manage leagues in the system</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/leagues/new"} color="primary">
            <.icon name="hero-plus" class="mr-1" /> New League
          </.button>
        </:actions>
      </.header>

      <div class="mt-6 bg-white rounded-lg border border-gray-200 p-4">
        <.form
          for={@filter_form}
          id="league-filters"
          phx-change="filter"
          phx-submit="filter"
          class="space-y-4"
        >
          <div class="flex gap-4 items-end">
            <div class="flex-1">
              <.input
                field={@filter_form[:search]}
                type="search"
                label="Search leagues"
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
          <%= if @leagues_empty? do %>
            No leagues found
          <% else %>
            Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
              @pagination.page * @pagination.per_page,
              @pagination.total_count
            )} of {@pagination.total_count} leagues
          <% end %>
        </span>
      </div>

      <div id="leagues" phx-update="stream" class="mt-4 space-y-4">
        <div id="empty-leagues" class="hidden only:block text-center py-8 text-gray-500">
          No leagues match your filters. Try adjusting your search criteria.
        </div>
        <div
          :for={{id, league} <- @streams.leagues}
          id={id}
          class="flex items-center justify-between p-4 bg-white rounded-lg border border-gray-200"
        >
          <div class="flex-1">
            <.link
              navigate={~p"/admin/leagues/#{league}"}
              class="text-lg font-semibold text-gray-900 hover:text-blue-600"
            >
              {league.name}
            </.link>
            <div class="text-sm text-gray-500 mt-1">
              <span :if={league.slug}>
                Slug: {league.slug}
              </span>
              <span :if={league.author} class="ml-4">
                Author: {league.author.email}
              </span>
              <span :if={league.seasons} class="ml-4">
                Seasons: {length(league.seasons)}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <.link navigate={~p"/admin/leagues/#{league}/edit"}>
              <.button variant="invisible">Edit</.button>
            </.link>
            <.button
              variant="invisible"
              phx-click="delete"
              phx-value-id={league.id}
              data-confirm="Are you sure you want to delete this league? This will also delete all associated seasons."
            >
              Delete
            </.button>
          </div>
        </div>
      </div>

      <.pagination
        page={@pagination.page}
        total_pages={@pagination.total_pages}
        path={~p"/admin/leagues"}
        params={filter_params_for_pagination(@filter_form)}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:leagues, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_filters(socket, params)}
  end

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    search = params["search"] || ""

    filter_params = %{
      "search" => search
    }

    leagues = list_leagues_filtered(socket.assigns.current_scope, search)
    total_count = length(leagues)
    per_page = @default_per_page
    total_pages = max(ceil(total_count / per_page), 1)
    offset = (page - 1) * per_page

    paginated_leagues = leagues |> Enum.drop(offset) |> Enum.take(per_page)

    pagination = %{
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }

    socket
    |> assign(:filter_form, to_form(filter_params, as: :filters))
    |> assign(:pagination, pagination)
    |> assign(:leagues_empty?, paginated_leagues == [])
    |> stream(:leagues, paginated_leagues, reset: true)
  end

  defp list_leagues_filtered(scope, search) do
    leagues = Leagues.list_leagues_with_preloads(scope)

    if search != "" do
      search_lower = String.downcase(search)

      Enum.filter(leagues, fn league ->
        String.contains?(String.downcase(league.name), search_lower) ||
          (league.slug && String.contains?(String.downcase(league.slug), search_lower))
      end)
    else
      leagues
    end
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
      "search" => filter_form[:search].value
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

    {:noreply, push_patch(socket, to: ~p"/admin/leagues?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/leagues")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    league = Leagues.get_league!(socket.assigns.current_scope, id)
    {:ok, _} = Leagues.delete_league(socket.assigns.current_scope, league)

    search = socket.assigns.filter_form[:search].value || ""
    leagues = list_leagues_filtered(socket.assigns.current_scope, search)
    total_count = length(leagues)
    per_page = @default_per_page
    total_pages = max(ceil(total_count / per_page), 1)
    page = socket.assigns.pagination.page
    offset = (page - 1) * per_page

    paginated_leagues = leagues |> Enum.drop(offset) |> Enum.take(per_page)

    pagination = %{
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }

    socket =
      if paginated_leagues == [] and page > 1 do
        params =
          socket.assigns.filter_form
          |> filter_params_for_pagination()
          |> Map.put("page", page - 1)

        push_patch(socket, to: ~p"/admin/leagues?#{params}")
      else
        socket
        |> assign(:pagination, pagination)
        |> assign(:leagues_empty?, paginated_leagues == [])
        |> stream(:leagues, paginated_leagues, reset: true)
      end

    {:noreply, socket}
  end
end
