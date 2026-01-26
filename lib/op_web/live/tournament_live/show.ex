defmodule OPWeb.TournamentLive.Show do
  use OPWeb, :live_view

  alias OP.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto">
        <div class="bg-[url('/images/wedgehead.webp')] bg-cover p-4">
          <div class="bg-white max-w-xl p-4 rounded">
            <div>
              <div class="text-xs flex justify-between">
                <.button
                  navigate={~p"/tournaments"}
                  color="invisible"
                  class="text-sm text-slate-700 flex items-center"
                >
                  <.icon name="hero-arrow-left" class="w-4 h-4 inline-block mr-1" /> Back
                </.button>
                <div class="flex items-center space-x-1">
                  <%= if DateTime.compare(@tournament.start_at, DateTime.utc_now()) == :lt do %>
                    <.badge color="warning">
                      Past
                    </.badge>
                  <% else %>
                    <.badge color="success">
                      Upcoming
                    </.badge>
                  <% end %>
                  <.link
                    navigate={~p"/seasons/#{@tournament.season.slug}"}
                    class="min-w-0 max-w-[200px]"
                  >
                    <.badge class="block">{@tournament.season.name}</.badge>
                  </.link>
                </div>
              </div>

              <h1 class="text-4xl font-bold rounded mt-1">{@tournament.name}</h1>
              <h2 class="text-xl font-medium mt-2">
                {Calendar.strftime(@tournament.start_at, "%a, %b %d, %Y at %I:%M %p %Z")}
              </h2>
              <h3
                :if={Ecto.assoc_loaded?(@tournament.location) && !is_nil(@tournament.location)}
                class=""
              >
                <.link navigate={~p"/locations/#{@tournament.location.slug}"} class="group">
                  <.underline>
                    @ {@tournament.location.name}
                  </.underline>
                </.link>
              </h3>
            </div>
          </div>
        </div>
      </div>
      <div class="container mx-auto p-4">
        <div class="mt-2">
          <.alert color="info" class="w-full max-w-full!">
            <p>An update for the tournament!</p>
            <div class="flex justify-end items-center">
              <.icon name="hero-arrow-left" class="size-4 mx-1" />
              <span class="text-sm">1 / 3</span>
              <.icon name="hero-arrow-right" class="size-4 mx-1" />
            </div>
          </.alert>
        </div>

        <div class="mt-2 ">
          <div class="bg-white p-4">
            <h1 class="text-2xl font-semibold">Description</h1>
            <p class="mt-2 break-words">
              {@tournament.description || "No description available."}
            </p>
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
end
