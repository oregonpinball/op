defmodule OPWeb.PlayerLive.Index do
  use OPWeb, :live_view

  alias OP.Players

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Manage Players
        <:actions>
          <.button navigate={~p"/admin/players/new"} color="primary">
            <.icon name="hero-plus" class="mr-1" /> New Player
          </.button>
        </:actions>
      </.header>

      <div class="mt-6">
        <.table id="players" rows={@streams.players}>
          <:col :let={{_id, player}} label="Name">{player.name}</:col>
          <:col :let={{_id, player}} label="External ID">{player.external_id || "-"}</:col>
          <:col :let={{_id, player}} label="Linked User">
            {if player.user, do: player.user.email, else: "-"}
          </:col>
          <:action :let={{_id, player}}>
            <.link navigate={~p"/admin/players/#{player.slug}/edit"}>
              <.button size="sm" variant="invisible">Edit</.button>
            </.link>
          </:action>
          <:action :let={{_id, player}}>
            <.button
              size="sm"
              color="error"
              variant="invisible"
              phx-click={JS.push("scrub", value: %{id: player.id})}
              data-confirm="Are you sure you want to scrub this player? This will anonymize their data but keep the record for historical purposes."
            >
              Scrub
            </.button>
          </:action>
        </.table>
        <div :if={@players_empty?} class="text-center text-base-content/70 py-8">
          No players found. Create your first player to get started.
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    players = Players.list_players_with_preloads(socket.assigns.current_scope)

    {:ok,
     socket
     |> assign(:players_empty?, players == [])
     |> stream(:players, players)}
  end

  @impl true
  def handle_event("scrub", %{"id" => id}, socket) do
    player = Players.get_player_with_preloads!(socket.assigns.current_scope, id)
    {:ok, scrubbed_player} = Players.scrub_player(socket.assigns.current_scope, player)

    # Reload with preloads for proper display
    scrubbed_player =
      Players.get_player_with_preloads!(socket.assigns.current_scope, scrubbed_player.id)

    players = Players.list_players_with_preloads(socket.assigns.current_scope)

    {:noreply,
     socket
     |> assign(:players_empty?, players == [])
     |> put_flash(:info, "Player scrubbed successfully")
     |> stream_insert(:players, scrubbed_player)}
  end
end
