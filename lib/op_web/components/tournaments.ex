defmodule OPWeb.Tournaments do
  use OPWeb, :html
  use Phoenix.Component

  alias OP.Tournaments.Tournament

  attr :calendar_date, Date, required: true
  attr :tournaments_by_date, :map, required: true
  attr :params, :map, required: true

  def calendar_month(assigns) do
    first = assigns.calendar_date
    days_in_month = Date.days_in_month(first)
    # 1 = Monday .. 7 = Sunday in Elixir; convert to Sun=0 based offset
    first_dow = Date.day_of_week(first)
    leading_blanks = rem(first_dow, 7)

    days = Enum.to_list(1..days_in_month)
    today = Date.utc_today()

    assigns =
      assigns
      |> assign(:leading_blanks, leading_blanks)
      |> assign(:days, days)
      |> assign(:today, today)

    ~H"""
    <div class="grid grid-cols-7 gap-px bg-gray-200 rounded-lg overflow-hidden border border-gray-200">
      <div
        :for={dow <- ~w(Sun Mon Tue Wed Thu Fri Sat)}
        class="bg-gray-50 p-2 text-center text-sm font-semibold text-gray-700"
      >
        {dow}
      </div>

      <div :for={_ <- 1..max(@leading_blanks, 0)//1} class="bg-white p-2 min-h-[80px]" />

      <div
        :for={day <- @days}
        class={[
          "bg-white p-2 min-h-[80px]",
          Date.new!(@calendar_date.year, @calendar_date.month, day) == @today &&
            "ring-2 ring-inset ring-emerald-500"
        ]}
      >
        <div class="text-sm font-medium text-gray-500">{day}</div>
        <div
          :for={
            t <-
              Map.get(
                @tournaments_by_date,
                Date.new!(@calendar_date.year, @calendar_date.month, day),
                []
              )
          }
          class="mt-0.5"
        >
          <.link
            navigate={~p"/tournaments/#{t.slug}"}
            class="block text-xs truncate text-emerald-700 hover:text-emerald-900 hover:underline font-medium"
          >
            {t.name}
          </.link>
        </div>
      </div>
    </div>
    """
  end

  attr :tournament, Tournament, required: true

  def card(assigns) do
    ~H"""
    <div class="rounded-lg bg-white shadow-sm hover:shadow-lg transition-all border-2 border-transparent hover:border-emerald-600">
      <.link navigate={~p"/tournaments/#{@tournament.slug}"}>
        <div class="bg-[url('/images/wedgehead.webp')] h-30 rounded-t bg-cover" />
      </.link>
      <div class="p-4">
        <.link navigate={~p"/tournaments/#{@tournament.slug}"}>
          <h1 class="text-2xl font-semibold rounded mt-1">{@tournament.name}</h1>
        </.link>

        <h2 class="text-normal font-medium mt-1">
          {Calendar.strftime(@tournament.start_at, "%a, %b %d, %Y at %-I:%M %p %Z")}
        </h2>

        <h3
          :if={Ecto.assoc_loaded?(@tournament.location) && !is_nil(@tournament.location)}
          class=""
        >
          <.link navigate={~p"/locations/#{@tournament.location.slug}"} class="">
            <.underline>
              @ {@tournament.location.name}
            </.underline>
          </.link>
        </h3>
        <%= if Ecto.assoc_loaded?(@tournament.season) && !is_nil(@tournament.season) do %>
          <div class="inline-flex space-x-1 mt-2 w-full">
            <.badge>{@tournament.season.name}</.badge>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
