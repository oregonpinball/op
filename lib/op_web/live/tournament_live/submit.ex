defmodule OPWeb.TournamentLive.Submit do
  use OPWeb, :live_view

  alias OP.Tournaments
  alias OP.Tournaments.Tournament

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4 max-w-3xl">
        <.live_component
          module={OPWeb.TournamentLive.SubmitForm}
          id={@tournament.id || :new}
          title={@page_title}
          action={@live_action}
          tournament={@tournament}
          current_scope={@current_scope}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if OP.FeatureFlags.tournament_submission_enabled?() do
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "Tournament submission is not currently available.")
       |> redirect(to: ~p"/tournaments")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Submit Tournament")
    |> assign(:tournament, %Tournament{standings: []})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    tournament =
      Tournaments.get_tournament_with_preloads!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Draft Tournament")
    |> assign(:tournament, tournament)
  end

  @impl true
  def handle_info({OPWeb.TournamentLive.SubmitForm, {:saved, _tournament}}, socket) do
    {:noreply, socket}
  end
end
