defmodule OPWeb.Landing do
  use OPWeb, :html
  use Phoenix.Component

  attr :current_scope, OP.Accounts.Scope, required: true, doc: "the current scope"

  attr :seasons, :list, default: [], doc: "list of seasons with rankings"
  attr :tournaments, :list, default: [], doc: "list of upcoming tournaments"
  attr :tournament_submission_enabled?, :boolean, default: false

  def authenticated(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <p class="text-center mt-2 font-bold text-lg md:hidden">Oregon Pinball</p>
      <h1 class="text-4xl font-bold text-center mt-2 text-slate-900 wrap-break-word">
        Welcome back, {@current_scope.user.email}
      </h1>
      <div class="mt-4 flex items-center justify-center space-x-2">
        <.button
          :if={@tournament_submission_enabled?}
          href={~p"/tournaments/submit"}
          color="primary"
          class="flex items-center space-x-1"
        >
          <.icon name="hero-plus" class="w-5 h-5" />
          <span>Submit tournament</span>
        </.button>
        <.button href={~p"/my/tournaments"} color="secondary" class="flex items-center space-x-1">
          <.icon name="hero-trophy" class="w-5 h-5" />
          <span>My tournaments</span>
        </.button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 mt-6 gap-6">
        <div class="col-span-1">
          <div class="grid grid-cols-2 gap-4">
            <div :if={is_map(@seasons.open)} class="p-4 bg-white shadow-xs rounded-lg">
              <h2 class="text-xl font-semibold text-center">
                <.link navigate={~p"/seasons/#{@seasons.open.slug}"}>{@seasons.open.name}</.link>
              </h2>
              <div class="mt-2 flex flex-col">
                <div :for={rank <- @seasons.open.rankings} class="truncate">
                  <Rankings.trophy ranking={rank.ranking} /> -
                  <.link
                    navigate={~p"/players/#{rank.player.slug}"}
                    class="underline rounded decoration-slate-400 hover:bg-slate-100 hover:decoration-slate-700 transition-all"
                  >
                    {rank.player.name}
                  </.link>
                </div>
              </div>
              <div class="flex justify-center mt-2">
                <.button navigate={~p"/seasons/#{@seasons.open.slug}"} color="invisible" size="md">
                  See all ->
                </.button>
              </div>
            </div>
            <div :if={is_map(@seasons.womens)} class="p-4 bg-white shadow-xs rounded-lg">
              <h2 class="text-xl font-semibold rounded-lg text-center">
                <.link navigate={~p"/seasons/#{@seasons.womens.slug}"}>{@seasons.womens.name}</.link>
              </h2>
              <div class="mt-2 flex flex-col">
                <div :for={rank <- @seasons.womens.rankings} class="truncate">
                  <Rankings.trophy ranking={rank.ranking} /> -
                  <.button navigate={~p"/players/#{rank.player.slug}"} variant="underline">
                    {rank.player.name}
                  </.button>
                </div>
              </div>
              <div class="flex justify-center mt-2">
                <.button navigate={~p"/seasons/#{@seasons.womens.slug}"} color="invisible" size="md">
                  See all ->
                </.button>
              </div>
            </div>
          </div>
        </div>

        <div>
          <h1 class="text-3xl font-semibold">Upcoming tournaments</h1>

          <div class="mt-4">
            <div class="space-y-4">
              <%= for tournament <- Enum.take(@tournaments, 3) do %>
                <OPWeb.Tournaments.card tournament={tournament} />
              <% end %>
            </div>
          </div>
          <div class="text-right mt-2">
            <.button navigate={~p"/tournaments"} color="invisible" size="md">
              See all tournaments ->
            </.button>
          </div>
        </div>
      </div>
    </div>

    <Layouts.footer />
    """
  end

  attr :tournaments, :list, default: [], doc: "list of upcoming tournaments"

  def public(assigns) do
    ~H"""
    <div
      id="landing-hero"
      class="md:h-150 border-b-2 border-green-700 flex md:place-items-center bg-[url('/images/illustration.png'),linear-gradient(to_top,#052e16,#011108)] bg-cover md:bg-contain md:bg-center bg-no-repeat"
    >
      <div class="p-2 md:p-8 container mx-auto rounded">
        <h1 class="text-center text-8xl text-slate-100 font-bold [text-shadow:3px_0_0_rgb(0_0_0),-3px_0_0_rgb(0_0_0),0_3px_0_rgb(0_0_0),0_-2px_0_rgb(0_0_0)]">
          Oregon Pinball
        </h1>
        <h2 class="mt-6 p-4 m-4 font-medium md:font-normal text-3xl md:text-4xl text-center bg-white/85 rounded">
          The home of Oregon competitive pinball. With resources for players, organizers, and operators.
        </h2>
        <div class="text-center my-8">
          <.button
            navigate={~p"/tournaments"}
            color="primary"
            size="xl"
            class="border-double border-4 border-white"
          >
            See our events
          </.button>
        </div>
      </div>
    </div>

    <div class="container mx-auto p-4">
      <p class="text-xl text-center">Welcome, we’re glad you’re here.</p>

      <div class="rounded border-2 p-4 mt-4">
        <h1 class="text-5xl font-semibold">Want to play?</h1>

        <div class="text-lg">
          <p class="mt-4">Two simple steps:</p>
          <p class="mt-2 pl-4">
            1. Review our Code of Conduct that is in place for every event we host.
          </p>
          <p class="mt-2 pl-4">
            2. Join any of our upcoming events:
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 grid-flow-row-dense gap-4 mt-4">
          <%= for tournament <- Enum.take(Enum.reverse(@tournaments), 3) do %>
            <OPWeb.Tournaments.card tournament={tournament} />
          <% end %>
        </div>

        <div class="text-right mt-2">
          <.button navigate={~p"/tournaments"} color="invisible" size="md">
            See all events ->
          </.button>
        </div>
      </div>

      <div class="rounded border-2 p-4 mt-4 bg-green-950 text-white">
        <h1 class=" text-5xl font-semibold">Want to host?</h1>

        <div class="text-lg">
          <p class="mt-2">Two simple steps to get going:</p>
          <p class="mt-2 pl-4">
            1. Review our Code of Conduct that you are expected to uphold in every event you host.
          </p>
          <p class="mt-2 pl-4">
            2. Submit your tournment to Oregon Pinball via the website here, you'll need an account to do so.
          </p>
        </div>
      </div>
    </div>

    <Layouts.footer />
    """
  end
end
