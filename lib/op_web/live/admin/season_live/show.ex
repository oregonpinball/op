defmodule OPWeb.Admin.SeasonLive.Show do
  use OPWeb, :live_view

  alias OP.Leagues

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@season.name}
        <:subtitle>Season details</:subtitle>
        <:actions>
          <.button variant="solid" phx-click="recalculate_rankings">
            Recalculate Rankings
          </.button>
          <.link navigate={~p"/admin/seasons/#{@season}/edit"}>
            <.button variant="solid">Edit Season</.button>
          </.link>
          <.link navigate={~p"/admin/seasons"}>
            <.button variant="invisible">Back to Seasons</.button>
          </.link>
        </:actions>
      </.header>

      <div class="mt-8 space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Basic Information</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm text-zinc-500">Name</dt>
                <dd class="text-zinc-900">{@season.name}</dd>
              </div>
              <div :if={@season.description}>
                <dt class="text-sm text-zinc-500">Description</dt>
                <dd class="text-zinc-900">{@season.description}</dd>
              </div>
              <div :if={@season.slug}>
                <dt class="text-sm text-zinc-500">Slug</dt>
                <dd class="text-zinc-900 font-mono text-sm">{@season.slug}</dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Schedule</h3>
            <dl class="space-y-3">
              <div :if={@season.start_at}>
                <dt class="text-sm text-zinc-500">Start Date</dt>
                <dd class="text-zinc-900">
                  {Calendar.strftime(@season.start_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>
              <div :if={@season.end_at}>
                <dt class="text-sm text-zinc-500">End Date</dt>
                <dd class="text-zinc-900">
                  {Calendar.strftime(@season.end_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Status</dt>
                <dd class="text-zinc-900">
                  {get_season_status(@season)}
                </dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Associations</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm text-zinc-500">League</dt>
                <dd class="text-zinc-900">
                  <%= if @season.league do %>
                    <.link
                      navigate={~p"/admin/leagues/#{@season.league}"}
                      class="text-blue-600 hover:text-blue-800"
                    >
                      {@season.league.name}
                    </.link>
                  <% else %>
                    None
                  <% end %>
                </dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Metadata</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm text-zinc-500">Created At</dt>
                <dd class="text-zinc-900">
                  {Calendar.strftime(@season.inserted_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Last Updated</dt>
                <dd class="text-zinc-900">
                  {Calendar.strftime(@season.updated_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <div class="mt-8">
          <h3 class="text-lg font-semibold text-zinc-900 mb-4">
            Player Rankings ({length(@rankings)})
          </h3>

          <%= if @rankings == [] do %>
            <p class="text-zinc-500">
              No rankings yet. Click "Recalculate Rankings" to generate rankings.
            </p>
          <% else %>
            <div class="bg-white rounded-lg border border-zinc-200 overflow-hidden">
              <table class="min-w-full divide-y divide-zinc-200">
                <thead class="bg-zinc-50">
                  <tr>
                    <th
                      class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider cursor-pointer hover:bg-zinc-100"
                      phx-click="sort"
                      phx-value-column="name"
                    >
                      <span class="flex items-center gap-1">
                        Player {sort_indicator("name", @sort_by, @sort_dir)}
                      </span>
                    </th>
                    <th
                      class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider cursor-pointer hover:bg-zinc-100"
                      phx-click="sort"
                      phx-value-column="ranking"
                    >
                      <span class="flex items-center gap-1">
                        Rank {sort_indicator("ranking", @sort_by, @sort_dir)}
                      </span>
                    </th>
                    <th
                      class="px-6 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider cursor-pointer hover:bg-zinc-100"
                      phx-click="sort"
                      phx-value-column="points"
                    >
                      <span class="flex items-center gap-1">
                        Points {sort_indicator("points", @sort_by, @sort_dir)}
                      </span>
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-zinc-200">
                  <tr :for={ranking <- @rankings} class="hover:bg-zinc-50">
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-900">
                      {ranking.player.name}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-900">
                      #{ranking.ranking}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-900">
                      {format_points(ranking.total_points)}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    season = Leagues.get_season_with_preloads!(socket.assigns.current_scope, id)

    rankings =
      Leagues.list_rankings_by_season_sorted(
        socket.assigns.current_scope,
        season.id,
        sort_by: "ranking",
        sort_dir: "asc"
      )

    {:ok,
     socket
     |> assign(:season, season)
     |> assign(:page_title, season.name)
     |> assign(:rankings, rankings)
     |> assign(:sort_by, "ranking")
     |> assign(:sort_dir, "asc")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("recalculate_rankings", _params, socket) do
    case Leagues.recalculate_season_rankings(
           socket.assigns.current_scope,
           socket.assigns.season.id
         ) do
      {:ok, count} ->
        rankings =
          Leagues.list_rankings_by_season_sorted(
            socket.assigns.current_scope,
            socket.assigns.season.id,
            sort_by: socket.assigns.sort_by,
            sort_dir: socket.assigns.sort_dir
          )

        {:noreply,
         socket
         |> assign(:rankings, rankings)
         |> put_flash(:info, "Rankings recalculated. #{count} player(s) ranked.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to recalculate rankings.")}
    end
  end

  @impl true
  def handle_event("sort", %{"column" => column}, socket) do
    current_sort_by = socket.assigns.sort_by
    current_sort_dir = socket.assigns.sort_dir

    new_dir =
      if column == current_sort_by do
        if current_sort_dir == "asc", do: "desc", else: "asc"
      else
        "asc"
      end

    rankings =
      Leagues.list_rankings_by_season_sorted(
        socket.assigns.current_scope,
        socket.assigns.season.id,
        sort_by: column,
        sort_dir: new_dir
      )

    {:noreply,
     socket
     |> assign(:rankings, rankings)
     |> assign(:sort_by, column)
     |> assign(:sort_dir, new_dir)}
  end

  defp get_season_status(season) do
    now = DateTime.utc_now()

    cond do
      season.start_at && DateTime.compare(season.start_at, now) == :gt ->
        "Upcoming"

      season.end_at && DateTime.compare(season.end_at, now) == :lt ->
        "Ended"

      season.start_at && season.end_at &&
        DateTime.compare(season.start_at, now) != :gt &&
          DateTime.compare(season.end_at, now) != :lt ->
        "Active"

      true ->
        "Unknown"
    end
  end

  defp sort_indicator(column, sort_by, sort_dir) when column == sort_by do
    if sort_dir == "asc" do
      Phoenix.HTML.raw(~s(<span class="text-zinc-700">&#9650;</span>))
    else
      Phoenix.HTML.raw(~s(<span class="text-zinc-700">&#9660;</span>))
    end
  end

  defp sort_indicator(_column, _sort_by, _sort_dir) do
    Phoenix.HTML.raw(~s(<span class="text-zinc-300">&#9650;</span>))
  end

  defp format_points(nil), do: "0.00"
  defp format_points(points), do: :erlang.float_to_binary(points / 1, decimals: 2)
end
