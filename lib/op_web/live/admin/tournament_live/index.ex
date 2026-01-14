defmodule OPWeb.Admin.TournamentLive.Index do
  use OPWeb, :live_view

  alias OP.Tournaments
  alias OP.Tournaments.Tournament

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Tournaments
        <:subtitle>Manage tournaments in the system</:subtitle>
        <:actions>
          <.link patch={~p"/admin/tournaments/new"}>
            <.button variant="solid">New Tournament</.button>
          </.link>
        </:actions>
      </.header>

      <div id="tournaments" phx-update="stream" class="mt-8 space-y-4">
        <div id="empty-tournaments" class="hidden only:block text-center py-8 text-zinc-500">
          No tournaments yet. Create your first tournament to get started.
        </div>
        <div
          :for={{id, tournament} <- @streams.tournaments}
          id={id}
          class="flex items-center justify-between p-4 bg-zinc-900 rounded-lg border border-zinc-800"
        >
          <div class="flex-1">
            <.link
              navigate={~p"/admin/tournaments/#{tournament}"}
              class="text-lg font-semibold text-white hover:text-blue-400"
            >
              {tournament.name}
            </.link>
            <div class="text-sm text-zinc-400 mt-1">
              <span :if={tournament.start_at}>
                {Calendar.strftime(tournament.start_at, "%B %d, %Y at %I:%M %p")}
              </span>
              <span :if={tournament.season} class="ml-4">
                Season: {tournament.season.name}
              </span>
              <span :if={tournament.location} class="ml-4">
                Location: {tournament.location.name}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <.link patch={~p"/admin/tournaments/#{tournament}/edit"}>
              <.button variant="invisible">Edit</.button>
            </.link>
            <.button
              variant="invisible"
              phx-click="delete"
              phx-value-id={tournament.id}
              data-confirm="Are you sure you want to delete this tournament?"
            >
              Delete
            </.button>
          </div>
        </div>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="tournament-modal"
        show
        on_cancel={JS.patch(~p"/admin/tournaments")}
      >
        <.live_component
          module={OPWeb.Admin.TournamentLive.FormComponent}
          id={@tournament.id || :new}
          title={@page_title}
          action={@live_action}
          tournament={@tournament}
          current_scope={@current_scope}
          patch={~p"/admin/tournaments"}
        />
      </.modal>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    tournaments = Tournaments.list_tournaments_with_preloads(socket.assigns.current_scope)

    {:ok,
     socket
     |> stream(:tournaments, tournaments)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tournament")
    |> assign(:tournament, Tournaments.get_tournament!(socket.assigns.current_scope, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tournament")
    |> assign(:tournament, %Tournament{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Tournaments")
    |> assign(:tournament, nil)
  end

  @impl true
  def handle_info({OPWeb.Admin.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    tournament =
      Tournaments.get_tournament_with_preloads!(socket.assigns.current_scope, tournament.id)

    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tournament = Tournaments.get_tournament!(socket.assigns.current_scope, id)
    {:ok, _} = Tournaments.delete_tournament(socket.assigns.current_scope, tournament)

    {:noreply, stream_delete(socket, :tournaments, tournament)}
  end
end
