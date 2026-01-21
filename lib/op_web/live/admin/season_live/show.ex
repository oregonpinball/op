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
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    season = Leagues.get_season_with_preloads!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:season, season)
     |> assign(:page_title, season.name)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("recalculate_rankings", _params, socket) do
    case Leagues.recalculate_season_rankings(socket.assigns.current_scope, socket.assigns.season.id) do
      {:ok, count} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rankings recalculated. #{count} player(s) ranked.")}

      {:error, _reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to recalculate rankings.")}
    end
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
end
