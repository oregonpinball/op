defmodule OPWeb.TournamentLive.Show do
  use OPWeb, :live_view

  alias OP.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-5xl mx-auto">
        <h1>Note: This is a placeholder UI to stub out the public tournament#show page</h1>
        <.header>
          {@tournament.name}
          <:subtitle :if={@tournament.start_at}>
            {Calendar.strftime(@tournament.start_at, "%B %d, %Y")}
          </:subtitle>
          <:actions>
            <.link navigate={~p"/tournaments"}>
              <.button variant="invisible">Back to Tournaments</.button>
            </.link>
          </:actions>
        </.header>

        <div class="mt-8 space-y-6">
          <%!-- Tournament Details --%>
          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h2 class="text-xl font-semibold text-zinc-900 mb-4">Tournament Details</h2>
            <dl class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-4">
              <div :if={@tournament.start_at}>
                <dt class="text-sm font-medium text-zinc-500">Date</dt>
                <dd class="mt-1 text-sm text-zinc-900">
                  {Calendar.strftime(@tournament.start_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>

              <div :if={@tournament.location}>
                <dt class="text-sm font-medium text-zinc-500">Location</dt>
                <dd class="mt-1 text-sm text-zinc-900">
                  <.link
                    navigate={~p"/locations/#{@tournament.location.slug}"}
                    class="text-emerald-600 hover:text-emerald-700"
                  >
                    {@tournament.location.name}
                  </.link>
                </dd>
              </div>

              <div :if={@tournament.season}>
                <dt class="text-sm font-medium text-zinc-500">Season</dt>
                <dd class="mt-1 text-sm text-zinc-900">
                  <.link
                    navigate={~p"/seasons/#{@tournament.season.slug}"}
                    class="text-emerald-600 hover:text-emerald-700"
                  >
                    {@tournament.season.name}
                  </.link>
                </dd>
              </div>

              <div :if={@tournament.organizer}>
                <dt class="text-sm font-medium text-zinc-500">Organizer</dt>
                <dd class="mt-1 text-sm text-zinc-900">
                  {@tournament.organizer.email}
                </dd>
              </div>

              <div :if={@tournament.qualifying_format && @tournament.qualifying_format != :none}>
                <dt class="text-sm font-medium text-zinc-500">Format</dt>
                <dd class="mt-1 text-sm text-zinc-900">
                  {format_qualifying_format(@tournament.qualifying_format)}
                </dd>
              </div>

              <div :if={@tournament.meaningful_games}>
                <dt class="text-sm font-medium text-zinc-500">Meaningful Games</dt>
                <dd class="mt-1 text-sm text-zinc-900">
                  {Float.round(@tournament.meaningful_games, 1)}
                </dd>
              </div>
            </dl>

            <div :if={@tournament.description} class="mt-6">
              <dt class="text-sm font-medium text-zinc-500 mb-2">Description</dt>
              <dd class="text-sm text-zinc-700 prose prose-sm max-w-none">
                {@tournament.description}
              </dd>
            </div>

            <div :if={@tournament.external_url} class="mt-6">
              <a
                href={@tournament.external_url}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center text-sm text-emerald-600 hover:text-emerald-700"
              >
                <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4 mr-1" /> View on Matchplay
              </a>
            </div>
          </div>

          <%!-- Standings --%>
          <div
            :if={@tournament.standings != []}
            class="bg-white rounded-lg border border-zinc-200 p-6"
          >
            <h2 class="text-xl font-semibold text-zinc-900 mb-4">Standings</h2>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-zinc-200">
                <thead>
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                      Position
                    </th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                      Player
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                      Total Points
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                      Linear
                    </th>
                    <th class="px-4 py-3 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                      Dynamic
                    </th>
                    <th
                      :if={has_finals_standings?(@tournament.standings)}
                      class="px-4 py-3 text-center text-xs font-medium text-zinc-500 uppercase tracking-wider"
                    >
                      Finals
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-zinc-200">
                  <tr
                    :for={standing <- @tournament.standings}
                    class={[
                      standing.is_finals && "bg-emerald-50"
                    ]}
                  >
                    <td class="px-4 py-3 whitespace-nowrap text-sm font-medium text-zinc-900">
                      {standing.position}
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-zinc-900">
                      <.link
                        :if={standing.player}
                        navigate={~p"/players/#{standing.player.slug}"}
                        class="text-emerald-600 hover:text-emerald-700"
                      >
                        {standing.player.name}
                      </.link>
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-zinc-900 text-right font-semibold">
                      {format_points(standing.total_points)}
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-zinc-500 text-right">
                      {format_points(standing.linear_points)}
                    </td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-zinc-500 text-right">
                      {format_points(standing.dynamic_points)}
                    </td>
                    <td
                      :if={has_finals_standings?(@tournament.standings)}
                      class="px-4 py-3 whitespace-nowrap text-sm text-center"
                    >
                      <span :if={standing.is_finals} class="inline-flex items-center">
                        <.icon name="hero-check-circle" class="w-5 h-5 text-emerald-600" />
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div
            :if={@tournament.standings == []}
            class="bg-white rounded-lg border border-zinc-200 p-8 text-center"
          >
            <p class="text-zinc-500">No standings available yet.</p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _url, socket) do
    tournament = Tournaments.get_tournament_by_slug!(socket.assigns.current_scope, slug)

    {:noreply,
     socket
     |> assign(:page_title, tournament.name)
     |> assign(:tournament, tournament)}
  end

  defp format_qualifying_format(format) do
    format
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp format_points(nil), do: "0.0"

  defp format_points(points) when is_float(points) do
    Float.round(points, 2) |> Float.to_string()
  end

  defp has_finals_standings?(standings) do
    Enum.any?(standings, & &1.is_finals)
  end
end
