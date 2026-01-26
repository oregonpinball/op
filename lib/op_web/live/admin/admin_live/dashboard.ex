defmodule OPWeb.Admin.AdminLive.Dashboard do
  use OPWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
      <.header>
        Admin Dashboard
      </.header>

      <div class="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <.admin_card
          title="Locations"
          description="Manage pinball venues and locations"
          href={~p"/admin/locations"}
          icon="hero-map-pin"
        />
        <.admin_card
          title="Tournaments"
          description="Manage pinball tournaments and events"
          href={~p"/admin/tournaments"}
          icon="hero-trophy"
        />
        <.admin_card
          title="Players"
          description="Manage player profiles and user links"
          href={~p"/admin/players"}
          icon="hero-users"
        />
        <.admin_card
          title="Leagues"
          description="Manage leagues and league settings"
          href={~p"/admin/leagues"}
          icon="hero-star"
        />
        <.admin_card
          title="Seasons"
          description="Manage seasons and associate with leagues"
          href={~p"/admin/seasons"}
          icon="hero-calendar"
        />
        <.admin_card
          title="Users"
          description="Manage user accounts and roles"
          href={~p"/admin/users"}
          icon="hero-user-circle"
        />
        <.admin_card
          title="Fir CMS"
          description="Manage sections and pages"
          href={~p"/admin/fir"}
          icon="hero-document"
        />
      </div>
      </div>
    </Layouts.app>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :href, :string, required: true
  attr :icon, :string, required: true

  defp admin_card(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class="group block rounded-lg border border-gray-200 p-6 hover:border-gray-300 hover:shadow-md transition-all"
    >
      <div class="flex items-center gap-4">
        <div class="flex size-12 items-center justify-center rounded-lg bg-gray-100 group-hover:bg-gray-200 transition-colors">
          <.icon name={@icon} class="size-6 text-gray-600" />
        </div>
        <div>
          <h3 class="font-semibold text-gray-900">{@title}</h3>
          <p class="text-sm text-gray-500">{@description}</p>
        </div>
      </div>
    </.link>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
