defmodule OPWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use OPWeb, :html

  import SaladUI.DropdownMenu

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :is_landing?, :boolean,
    default: false,
    doc: "whether to render the landing page layout variant"

  slot :inner_block, required: true

  def app(assigns) do
    nav_classes = if assigns.is_landing?, do: "md:-mb-24", else: "bg-green-950"
    assigns = Map.put(assigns, :nav_classes, nav_classes)

    ~H"""
    <.sheet id="mobile-nav">
      <%= if is_nil(@current_scope) do %>
        <.button
          navigate={~p"/"}
          color="invisible"
          class="text-2xl font-bold! hover:text-slate-900 transition-all"
        >
          Oregon Pinball
        </.button>

        <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
          About
        </.button>
        <.button
          navigate={~p"/tournaments"}
          color="invisible"
          class="hover:text-slate-900 transition-all"
        >
          Our events
        </.button>
        <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
          Play in an event
        </.button>
        <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
          Host an event
        </.button>
      <% else %>
      <% end %>
    </.sheet>

    <nav
      id="nav-op"
      class={[@nav_classes, "sticky top-0 z-10 transition-all duration-100 md:p-1"]}
      phx-hook="BackgroundColorWatcher"
    >
      <div class="container mx-auto">
        <div class="hidden md:block">
          <%= if is_nil(@current_scope) do %>
            <div class="text-white flex items-center space-x-1">
              <.button
                navigate={~p"/"}
                color="invisible"
                class="text-2xl font-bold! hover:text-slate-900 transition-all"
              >
                Oregon Pinball
              </.button>

              <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
                About
              </.button>
              <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
                Play in an event
              </.button>
              <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
                Host an event
              </.button>
              <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
                Code of Conduct
              </.button>
              <.button
                navigate={~p"/users/register"}
                color="invisible"
                size="sm"
                class="ml-auto hover:text-slate-900 transition-all"
              >
                Register
              </.button>
              <.button
                navigate={~p"/users/log-in"}
                color="invisible"
                class="hover:text-slate-900 transition-all"
              >
                Log in
              </.button>
            </div>
          <% else %>
            <div class="text-white flex items-center space-x-1">
              <.button
                navigate={~p"/"}
                color="invisible"
                class="text-2xl font-bold! hover:text-slate-900 transition-all"
              >
                Oregon Pinball
              </.button>

              <.button
                navigate={~p"/tournaments"}
                color="invisible"
                class="hover:text-slate-900 transition-all"
              >
                Tournaments
              </.button>
              <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
                Host an event
              </.button>
              <.button navigate={~p"/"} color="invisible" class="hover:text-slate-900 transition-all">
                Code of Conduct
              </.button>

              <.dropdown_menu id="nav-dropdown" class="ml-auto text-slate-900">
                <.dropdown_menu_trigger>
                  <.button>
                    <div class="rounded-full size-6 bg-white" />
                    <.icon name="hero-chevron-down" class="size-4 place-self-end ml-1" />
                  </.button>
                </.dropdown_menu_trigger>
                <.dropdown_menu_content class="w-56" align="end">
                  <div class="flex flex-col p-2">
                    <div class="font-medium">My account</div>
                    <hr class="h-0.5 border-0 bg-slate-200 rounded m-1" />
                    <.nav_buttons_shared current_scope={@current_scope} />
                  </div>
                </.dropdown_menu_content>
              </.dropdown_menu>
            </div>
          <% end %>
        </div>

        <div class="block md:hidden">
          <.button
            phx-click={toggle("#mobile-nav")}
            color="invisible"
            class="absolute top-1 right-2 rounded-full bg-white border-2 border-green-950! p-1!"
          >
            <.icon name="hero-bars-3" class="size-6 text-black hover:cursor-pointer" />
          </.button>
        </div>
      </div>
    </nav>

    <main class="">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders navigation buttons for the layout for normal and mobile.
  """
  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :class, :string, default: "", doc: "additional classes for the nav container"
  attr :is_mobile?, :boolean, default: false, doc: "whether the nav is for mobile view"

  def nav_buttons(assigns) do
    class =
      if assigns.is_mobile?,
        do: assigns.class <> " flex flex-col",
        else: assigns.class <> " hidden md:flex items-center justify-between space-x-2"

    assigns = Map.put(assigns, :class, class)

    ~H"""
    <ul class={[@class]}>
      <li class="">
        <.button navigate={~p"/"} color="invisible">
          <span class="font-semibold">Open Pinball</span>
        </.button>
      </li>

      <li>
        <.button navigate={~p"/tournaments"} color="invisible">Tournaments</.button>
      </li>
      <%= if @current_scope do %>
        <li>
          <%= if @is_mobile? do %>
            <.nav_buttons_shared current_scope={@current_scope} />
          <% else %>
            <.dropdown_menu id="nav-dropdown">
              <.dropdown_menu_trigger>
                <.button>
                  <.icon name="hero-bars-3" class="size-6" />
                </.button>
              </.dropdown_menu_trigger>
              <.dropdown_menu_content class="w-56" align="end">
                <div class="flex flex-col p-2">
                  <div class="font-medium">My account</div>
                  <hr class="h-0.5 border-0 bg-slate-200 rounded m-1" />
                  <.nav_buttons_shared current_scope={@current_scope} />
                </div>
              </.dropdown_menu_content>
            </.dropdown_menu>
          <% end %>
        </li>
      <% else %>
        <li>
          <.button navigate={~p"/users/register"} color="invisible">Register</.button>
        </li>
        <li>
          <.button navigate={~p"/users/log-in"} color="primary">Log in</.button>
        </li>
      <% end %>
    </ul>

    <ul :if={!@is_mobile?} class="flex justify-end md:hidden">
      <li class="">
        <.button
          phx-click={toggle("#mobile-nav")}
          color="invisible"
          class="rounded-full bg-white border-2 border-green-950! p-1! mr-2 mt-2"
        >
          <.icon name="hero-bars-3" class="size-6 text-black hover:cursor-pointer" />
        </.button>
      </li>
    </ul>
    """
  end

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  def nav_buttons_shared(assigns) do
    ~H"""
    <div class="space-y-0.5 flex flex-col">
      <.link :if={is_system_admin?(@current_scope)} navigate={~p"/admin/dashboard"}>
        <.icon name="hero-wrench" class="size-4" />
        <span>Admin dashboard</span>
      </.link>
      <.link navigate={~p"/users/settings"} class="dropdown-menu-item">
        <.icon name="hero-cog-6-tooth" class="size-4" />
        <span>Settings</span>
      </.link>
      <.link href={~p"/users/log-out"} method="delete">
        <.icon name="hero-arrow-left-end-on-rectangle" class="h-4 w-4" />
        <span>Log out</span>
      </.link>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
