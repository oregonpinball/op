defmodule OPWeb.Landing do
  use OPWeb, :html
  use Phoenix.Component

  attr :current_scope, OP.Accounts.Scope, required: true, doc: "the current scope"

  attr :seasons, :list, default: [], doc: "list of seasons with rankings"
  attr :tournaments, :list, default: [], doc: "list of upcoming tournaments"

  def authenticated(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <p class="text-center mt-2 font-bold text-lg md:hidden">Oregon Pinball</p>
      <h1 class="text-4xl font-bold text-center mt-2 text-slate-900 wrap-break-word">
        Welcome back, {@current_scope.user.email}
      </h1>
      <div class="mt-4 flex items-center justify-center space-x-2">
        <.button color="primary" size="lg">Add tournament</.button>
        <.button color="secondary" size="lg">Submit results</.button>
        <.button color="secondary" size="lg">View submissions</.button>
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

          <div class="mt-4 grid grid-cols-1 md:grid-cols-4 gap-4">
            <div class="space-y-4 order-2 md:order-1 md:col-span-3">
              <%= for tournament <- @tournaments do %>
                <.link
                  navigate={~p"/tournaments"}
                  class="bg-white block border-2 border-slate-300 shadow-xs rounded-lg hover:border-emerald-700 hover:bg-slate-50 hover:scale-101 transition-all group"
                >
                  <div class="grid grid-cols-3">
                    <div class="col-span-3 md:col-span-2">
                      <div class="relative block mx-auto md:hidden">
                        <div class="block mx-auto md:hidden h-32 bg-[url('/images/wedgehead.webp')] bg-cover rounded">
                        </div>
                        <div class="absolute top-0 right-0 flex justify-end p-2">
                          <div class="bg-white size-12 border-2 border-slate-200 rounded-full bg-cover bg-[url('/images/dogsoccer.png')]">
                          </div>
                        </div>
                      </div>

                      <div class="p-4">
                        <div class="flex flex-col">
                          <h3 class="text-2xl font-semibold text-slate-900">Monthly League Finals</h3>
                        </div>
                        <p class="font-medium mt-1">
                          Mon, May 9
                          <.icon
                            name="hero-clock"
                            class="size-4 inline stroke-black relative -top-0.5"
                          /> 5:00 PM PST
                        </p>
                        <%= if Ecto.assoc_loaded?(tournament.location) && !is_nil(tournament.location) do %>
                          <p class="text-slate-700">@ {tournament.location.name}</p>
                        <% end %>
                        <p class="text-slate-500 text-sm mt-1">Hosted by Dog Soccer Entertainment</p>

                        <div class="inline-flex space-x-1 mt-2 w-full">
                          <.badge>$5</.badge>
                          <.badge>Open</.badge>
                        </div>
                      </div>
                    </div>

                    <div class="hidden md:flex md:flex-col md:items-end md:justify-end">
                      <div class="flex flex-col top-0 w-full h-full text-right bg-cover bg-no-repeat [--mask-stop:25%] group-hover:[--mask-stop:20%] bg-[url('/images/wedgehead.webp')] [-webkit-mask-image:linear-gradient(115deg,transparent_0%,transparent_calc(var(--mask-stop)-1px),black_var(--mask-stop),black_100%)] mask-[linear-gradient(115deg,transparent_0%,transparent_calc(var(--mask-stop)-1px),black_var(--mask-stop),black_100%)] transition-[--mask-stop] duration-300 ease-in-out rounded-r-lg">
                        <div class="flex justify-end p-2">
                          <div class="bg-white size-12 border-2 border-slate-200 rounded-full bg-cover bg-[url('/images/dogsoccer.png')]">
                          </div>
                        </div>
                        <div class="h-full flex items-end justify-end p-2">
                          <.badge class="group-hover:bg-white group-hover:border-amber-200 group-hover:opacity-100">
                            Details ->
                          </.badge>
                        </div>
                      </div>
                    </div>
                  </div>
                </.link>
              <% end %>
            </div>

            <div class="order-1 md:order-2 space-x-1 md:space-y-1">
              <h1>Filters</h1>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Crawl
              </span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Women's
              </span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Open
              </span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Certified
              </span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Major
              </span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Chaos
              </span>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800">
                Starts early
              </span>
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
            <div class="rounded-lg bg-white shadow-sm hover:shadow-lg transition-all">
              <.link navigate={~p"/tournaments/#{tournament.slug}"}>
                <div class="bg-[url('/images/wedgehead.webp')] h-30 rounded-t-lg bg-cover" />
              </.link>
              <div class="p-4">
                <.link navigate={~p"/tournaments/#{tournament.slug}"}>
                  <h1 class="text-2xl font-semibold rounded mt-1">{tournament.name}</h1>
                </.link>

                <h2 class="text-normal font-medium mt-1">
                  {Calendar.strftime(tournament.start_at, "%a, %b %d, %Y at %-I:%M %p %Z")}
                </h2>

                <h3
                  :if={Ecto.assoc_loaded?(tournament.location) && !is_nil(tournament.location)}
                  class=""
                >
                  <.link navigate={~p"/locations/#{tournament.location.slug}"} class="">
                    <.underline>
                      @ {tournament.location.name}
                    </.underline>
                  </.link>
                </h3>
                <div class="inline-flex space-x-1 mt-2 w-full">
                  <.badge>$5</.badge>
                  <.badge>Open</.badge>
                </div>
              </div>
            </div>
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

    <div class="bg-[#011108] bg-linear-to-b from-[#052e16] to-[#011108] border-t-4 border-green-700 text-white">
      <div class="container mx-auto p-4">
        <div class="grid grid-cols-1 md:grid-cols-4">
          <div>
            <p class="font-bold text-lg">What is Oregon Pinball?</p>
            <ul>
              <li>About us</li>
              <li>Our board</li>
              <li>Our rules</li>
            </ul>
          </div>

          <div>
            <p class="font-bold text-lg">Play</p>
            <ul>
              <li>View events</li>
              <li>Code of Conduct</li>
              <li>Rules</li>
            </ul>
          </div>

          <ul class="">
            <p class="font-bold text-lg">Host</p>
            <ul>
              <li>Submit an event</li>
              <li>Code of Conduct</li>
              <li>Rules</li>
            </ul>
          </ul>

          <div class="flex md:justify-end md:items-end">
            <p class="">© 2026 Oregon Pinball</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
