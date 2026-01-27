defmodule OPWeb.Tournaments do
  use OPWeb, :html
  use Phoenix.Component

  alias OP.Tournaments.Tournament

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
