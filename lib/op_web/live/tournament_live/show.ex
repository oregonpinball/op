defmodule OPWeb.TournamentLive.Show do
  use OPWeb, :live_view

  alias OP.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div
        class="bg-linear-to-b from-black to-slate-700 bg-cover"
        style={"background-image: url('#{OPWeb.Tournaments.banner_url(@tournament)}')"}
      >
        <div class="container mx-auto pt-4 px-4">
          <div class="col-span-1 md:col-span-6 bg-white/95 p-4 rounded-t">
            <div class="">
              <div class="text-xs flex justify-between">
                <.button
                  navigate={~p"/tournaments"}
                  color="invisible"
                  class="text-sm text-slate-700 flex items-center"
                >
                  <.icon name="hero-arrow-left" class="w-4 h-4 inline-block mr-1" /> Back
                </.button>
                <div class="flex items-center space-x-1">
                  <%= if @tournament.qualifying_format != :none do %>
                    <.badge color="secondary">
                      {@tournament.qualifying_format}
                    </.badge>
                  <% end %>
                  <%= if @tournament.finals_format != :none do %>
                    <.badge color="secondary">
                      {@tournament.finals_format}
                    </.badge>
                  <% end %>
                  <.link
                    :if={Ecto.assoc_loaded?(@tournament.season) && !is_nil(@tournament.season)}
                    navigate={~p"/seasons/#{@tournament.season.slug}"}
                    class="min-w-0 max-w-[200px]"
                  >
                    <.badge class="block">{@tournament.season.name}</.badge>
                  </.link>
                </div>
              </div>

              <p class="text-lg font-slate-800">Tournament</p>
              <h1 class="text-5xl font-bold rounded leading-10">{@tournament.name}</h1>
              <div class="mt-1 flex items-center space-x-2">
                <%= if DateTime.compare(@tournament.start_at, DateTime.utc_now()) == :lt do %>
                  <.badge color="warning">
                    Past
                  </.badge>
                <% else %>
                  <.badge color="success">
                    Upcoming
                  </.badge>
                <% end %>
                <h2 class="text-xl font-medium mt-1">
                  <time
                    id="tournament-show-time"
                    phx-hook="LocalTime"
                    data-datetime={DateTime.to_iso8601(@tournament.start_at)}
                    data-format="full"
                  >
                    <div class="w-full bg-slate-100 rounded h-4" />
                  </time>
                </h2>
              </div>
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
      <div class="container mx-auto px-4 pb-4">
        <div class="bg-white p-4 rounded-b">
          <h1 class="text-3xl font-semibold">Description</h1>
          <p class="mt-2 break-words">
            {@tournament.description || "No description available."}
          </p>
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
