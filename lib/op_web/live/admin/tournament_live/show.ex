defmodule OPWeb.Admin.TournamentLive.Show do
  use OPWeb, :live_view

  alias OP.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@tournament.name}
        <:subtitle>Tournament details</:subtitle>
        <:actions>
          <.link patch={~p"/admin/tournaments/#{@tournament}/edit"}>
            <.button variant="solid">Edit Tournament</.button>
          </.link>
          <.link navigate={~p"/admin/tournaments"}>
            <.button variant="invisible">Back to Tournaments</.button>
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
                <dd class="text-zinc-900">{@tournament.name}</dd>
              </div>
              <div :if={@tournament.description}>
                <dt class="text-sm text-zinc-500">Description</dt>
                <dd class="text-zinc-900">{@tournament.description}</dd>
              </div>
              <div :if={@tournament.slug}>
                <dt class="text-sm text-zinc-500">Slug</dt>
                <dd class="text-zinc-900 font-mono text-sm">{@tournament.slug}</dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Schedule</h3>
            <dl class="space-y-3">
              <div :if={@tournament.start_at}>
                <dt class="text-sm text-zinc-500">Start Date</dt>
                <dd class="text-zinc-900">
                  {Calendar.strftime(@tournament.start_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>
              <div :if={@tournament.end_at}>
                <dt class="text-sm text-zinc-500">End Date</dt>
                <dd class="text-zinc-900">
                  {Calendar.strftime(@tournament.end_at, "%B %d, %Y at %I:%M %p")}
                </dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Associations</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm text-zinc-500">Season</dt>
                <dd class="text-zinc-900">
                  {if @tournament.season, do: @tournament.season.name, else: "None"}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Location</dt>
                <dd class="text-zinc-900">
                  {if @tournament.location, do: @tournament.location.name, else: "None"}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Organizer</dt>
                <dd class="text-zinc-900">
                  {if @tournament.organizer, do: @tournament.organizer.email, else: "None"}
                </dd>
              </div>
            </dl>
          </div>

          <div class="bg-white rounded-lg border border-zinc-200 p-6">
            <h3 class="text-lg font-semibold text-zinc-900 mb-4">Configuration</h3>
            <dl class="space-y-3">
              <div>
                <dt class="text-sm text-zinc-500">Event Booster</dt>
                <dd class="text-zinc-900 capitalize">
                  {Phoenix.Naming.humanize(@tournament.event_booster)}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Qualifying Format</dt>
                <dd class="text-zinc-900 capitalize">
                  {Phoenix.Naming.humanize(@tournament.qualifying_format)}
                </dd>
              </div>
              <div>
                <dt class="text-sm text-zinc-500">Allows Opt-Out</dt>
                <dd class="text-zinc-900">{if @tournament.allows_opt_out, do: "Yes", else: "No"}</dd>
              </div>
            </dl>
          </div>
        </div>

        <div
          :if={@tournament.base_value || @tournament.tgp}
          class="bg-white rounded-lg border border-zinc-200 p-6"
        >
          <h3 class="text-lg font-semibold text-zinc-900 mb-4">Ratings & Values</h3>
          <dl class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div :if={@tournament.base_value}>
              <dt class="text-sm text-zinc-500">Base Value</dt>
              <dd class="text-zinc-900">{@tournament.base_value}</dd>
            </div>
            <div :if={@tournament.tgp}>
              <dt class="text-sm text-zinc-500">TGP</dt>
              <dd class="text-zinc-900">{@tournament.tgp}</dd>
            </div>
            <div :if={@tournament.tva_rating}>
              <dt class="text-sm text-zinc-500">TVA Rating</dt>
              <dd class="text-zinc-900">{@tournament.tva_rating}</dd>
            </div>
            <div :if={@tournament.tva_ranking}>
              <dt class="text-sm text-zinc-500">TVA Ranking</dt>
              <dd class="text-zinc-900">{@tournament.tva_ranking}</dd>
            </div>
            <div :if={@tournament.total_tva}>
              <dt class="text-sm text-zinc-500">Total TVA</dt>
              <dd class="text-zinc-900">{@tournament.total_tva}</dd>
            </div>
            <div :if={@tournament.first_place_value}>
              <dt class="text-sm text-zinc-500">First Place Value</dt>
              <dd class="text-zinc-900">{@tournament.first_place_value}</dd>
            </div>
          </dl>
        </div>

        <div
          :if={@tournament.standings != [] && @tournament.meaningful_games}
          class="bg-white rounded-lg border border-zinc-200 p-6"
        >
          <% standings_with_weight = standings_with_weight(@tournament) %>
          <% first_place = Enum.find(@tournament.standings, &(&1.position == 1)) %>
          <% first_place_value = if first_place, do: first_place.total_points || 0.0, else: 0.0 %>
          <% player_count = length(@tournament.standings) %>
          <% tgp = ((@tournament.meaningful_games || 0) * 0.04) |> min(2.0) %>

          <div class="mb-6 grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <dt class="text-sm text-zinc-500">TGP</dt>
              <dd class="text-2xl font-semibold">{format_tgp_percent(tgp)}</dd>
            </div>
            <div>
              <dt class="text-sm text-zinc-500">First Place Value</dt>
              <dd class="text-2xl font-semibold">{format_points(first_place_value)}</dd>
            </div>
            <div>
              <dt class="text-sm text-zinc-500">Players</dt>
              <dd class="text-2xl font-semibold">{player_count}</dd>
            </div>
            <div>
              <dt class="text-sm text-zinc-500">Meaningful Games</dt>
              <dd class="text-2xl font-semibold">{@tournament.meaningful_games}</dd>
            </div>
          </div>

          <h3 class="text-lg font-semibold text-zinc-900 mb-4">Point Breakdown</h3>
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-zinc-200">
              <thead>
                <tr>
                  <th class="px-3 py-2 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                    Pos
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-zinc-500 uppercase tracking-wider">
                    Player
                  </th>
                  <th class="px-3 py-2 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                    Linear
                  </th>
                  <th class="px-3 py-2 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                    Dynamic
                  </th>
                  <th class="px-3 py-2 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                    Total
                  </th>
                  <th class="px-3 py-2 text-right text-xs font-medium text-zinc-500 uppercase tracking-wider">
                    Weight
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-zinc-100">
                <tr :for={standing <- standings_with_weight} class="hover:bg-zinc-50">
                  <td class="px-3 py-2 text-sm text-zinc-900 font-medium">
                    {standing.position}
                  </td>
                  <td class="px-3 py-2 text-sm text-zinc-900">
                    <.link
                      navigate={~p"/admin/players/#{standing.player.slug}/edit"}
                      class="text-blue-600 hover:text-blue-800 hover:underline"
                    >
                      {standing.player.name}
                    </.link>
                  </td>
                  <td class="px-3 py-2 text-sm text-zinc-900 text-right font-mono">
                    {format_points(standing.linear_points)}
                  </td>
                  <td class="px-3 py-2 text-sm text-zinc-900 text-right font-mono">
                    {format_points(standing.dynamic_points)}
                  </td>
                  <td class="px-3 py-2 text-sm text-zinc-900 text-right font-mono font-semibold">
                    {format_points(standing.total_points)}
                  </td>
                  <td class="px-3 py-2 text-sm text-zinc-900 text-right font-mono">
                    {format_weight_percent(standing.weight)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action == :edit}
        id="tournament-modal"
        show
        on_cancel={JS.patch(~p"/admin/tournaments/#{@tournament}")}
      >
        <.live_component
          module={OPWeb.Admin.TournamentLive.FormComponent}
          id={@tournament.id}
          title="Edit Tournament"
          action={@live_action}
          tournament={@tournament}
          current_scope={@current_scope}
          patch={~p"/admin/tournaments/#{@tournament}"}
        />
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tournament = Tournaments.get_tournament_with_preloads!(socket.assigns.current_scope, id)
    {:ok, assign(socket, :tournament, tournament)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  @impl true
  def handle_info({OPWeb.Admin.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    tournament =
      Tournaments.get_tournament_with_preloads!(socket.assigns.current_scope, tournament.id)

    {:noreply, assign(socket, :tournament, tournament)}
  end

  defp standings_with_weight(tournament) do
    first_place_total =
      tournament.standings
      |> Enum.find(&(&1.position == 1))
      |> then(fn
        nil -> 0.0
        standing -> standing.total_points || 0.0
      end)

    tournament.standings
    |> Enum.sort_by(& &1.position)
    |> Enum.map(fn standing ->
      weight =
        if first_place_total > 0,
          do: (standing.total_points || 0.0) / first_place_total,
          else: 0.0

      Map.put(standing, :weight, weight)
    end)
  end

  defp format_points(nil), do: "-"
  defp format_points(value), do: :erlang.float_to_binary(value / 1, decimals: 2)

  defp format_tgp_percent(nil), do: "-"
  defp format_tgp_percent(tgp), do: "#{round(tgp * 100)}%"

  defp format_weight_percent(nil), do: "-"
  defp format_weight_percent(weight), do: "#{Float.round(weight * 100, 1)}%"
end
