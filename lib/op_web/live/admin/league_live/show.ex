defmodule OPWeb.Admin.LeagueLive.Show do
  use OPWeb, :live_view

  alias OP.Leagues

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@league.name}
        <:subtitle>League details</:subtitle>
        <:actions>
          <.link navigate={~p"/admin/leagues/#{@league}/edit"}>
            <.button variant="solid">Edit League</.button>
          </.link>
          <.link navigate={~p"/admin/leagues"}>
            <.button variant="invisible">Back to Leagues</.button>
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
                <dd class="text-zinc-900">{@league.name}</dd>
              </div>
              <div :if={@league.description}>
                <dt class="text-sm text-zinc-500">Description</dt>
                <dd class="text-zinc-900">{@league.description}</dd>
              </div>
              <div :if={@league.slug}>
                <dt class="text-sm text-zinc-500">Slug</dt>
                <dd class="text-zinc-900 font-mono text-sm">{@league.slug}</dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Associations</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm text-zinc-500">Author</dt>
                <dd class="text-zinc-900">
                  {if @league.author, do: @league.author.email, else: "None"}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Total Seasons</dt>
                <dd class="text-zinc-900">
                  {if @league.seasons, do: length(@league.seasons), else: 0}
                </dd>
              </div>
            </dl>
          </div>
        </div>

        <div class="bg-white rounded-lg border border-zinc-200 p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-zinc-900">Seasons</h3>
            <.link navigate={~p"/admin/seasons/new?league_id=#{@league.id}"}>
              <.button variant="solid">Add Season</.button>
            </.link>
          </div>

          <div :if={@league.seasons && @league.seasons != []} class="space-y-2">
            <div
              :for={season <- @league.seasons}
              class="flex items-center justify-between p-3 bg-zinc-50 rounded-lg"
            >
              <div>
                <.link
                  navigate={~p"/admin/seasons/#{season}"}
                  class="font-medium text-zinc-900 hover:text-blue-600"
                >
                  {season.name}
                </.link>
                <div class="text-sm text-zinc-500">
                  <span :if={season.start_at}>
                    {Calendar.strftime(season.start_at, "%B %d, %Y")}
                  </span>
                  <span :if={season.end_at}>
                    - {Calendar.strftime(season.end_at, "%B %d, %Y")}
                  </span>
                </div>
              </div>
              <.link navigate={~p"/admin/seasons/#{season}"}>
                <.button variant="invisible">View</.button>
              </.link>
            </div>
          </div>

          <div :if={!@league.seasons || @league.seasons == []} class="text-center py-8 text-zinc-500">
            No seasons associated with this league yet.
          </div>
        </div>

        <div class="bg-white rounded-lg border border-zinc-200 p-6">
          <h3 class="text-lg font-semibold text-zinc-900 mb-4">Metadata</h3>
          <dl class="space-y-3">
            <div>
              <dt class="text-sm text-zinc-500">Created At</dt>
              <dd class="text-zinc-900">
                {Calendar.strftime(@league.inserted_at, "%B %d, %Y at %I:%M %p")}
              </dd>
            </div>
            <div>
              <dt class="text-sm text-zinc-500">Last Updated</dt>
              <dd class="text-zinc-900">
                {Calendar.strftime(@league.updated_at, "%B %d, %Y at %I:%M %p")}
              </dd>
            </div>
          </dl>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    league = Leagues.get_league_with_preloads!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:league, league)
     |> assign(:page_title, league.name)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
