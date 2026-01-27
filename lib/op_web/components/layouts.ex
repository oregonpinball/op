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

        <.button
          navigate={~p"/f/about/us"}
          color="invisible"
          class="hover:text-slate-900 transition-all"
        >
          About
        </.button>
        <.button
          navigate={~p"/tournaments"}
          color="invisible"
          class="hover:text-slate-900 transition-all"
        >
          Our events
        </.button>
        <.button
          navigate={~p"/f/how-tos/play-in-an-event"}
          color="invisible"
          class="hover:text-slate-900 transition-all"
        >
          Play in an event
        </.button>
        <.button
          navigate={~p"/f/how-tos/host-a-certified-event"}
          color="invisible"
          class="hover:text-slate-900 transition-all"
        >
          Host an event
        </.button>
      <% else %>
      <% end %>
    </.sheet>

    <div class="flex flex-col h-screen overflow-y-auto">
      <nav
        id="nav-op"
        class={[@nav_classes, "sticky top-0 z-10 transition-all duration-100 md:p-1"]}
        phx-hook="BackgroundColorWatcher"
      >
        <div class="container mx-auto">
          <div class="hidden md:block">
            <div class="text-white flex items-center space-x-1">
              <.button
                navigate={~p"/"}
                color="invisible"
                class="truncate text-2xl font-bold! hover:text-slate-900 transition-all"
              >
                <span class="">Oregon Pinball</span>
              </.button>

              <.button
                navigate={~p"/tournaments"}
                color="invisible"
                class="truncate hover:text-slate-900 transition-all"
              >
                <span class="truncate">
                  <span class="hidden lg:block">Join an event</span>
                  <span class="block lg:hidden">Join</span>
                </span>
              </.button>
              <.button
                navigate={~p"/f/how-tos/host-a-certified-event"}
                color="invisible"
                class="truncate hover:text-slate-900 transition-all"
              >
                <span class="hidden lg:block">Host an event</span>
                <span class="block lg:hidden">Host</span>
              </.button>
              <.button
                navigate={~p"/f/rules/code-of-conduct"}
                color="invisible"
                class="truncate hover:text-slate-900 transition-all"
              >
                <span class="truncate">Code of Conduct</span>
              </.button>
              <.button
                navigate={~p"/f/about/us"}
                color="invisible"
                class="truncate hover:text-slate-900 transition-all"
              >
                <span class="truncate">About</span>
              </.button>

              <%= if is_nil(@current_scope) do %>
                <.button
                  navigate={~p"/users/register"}
                  color="invisible"
                  size="sm"
                  class="ml-auto hover:text-slate-900 transition-all"
                >
                  <span class="truncate">Register</span>
                </.button>
                <.button
                  navigate={~p"/users/log-in"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  <span class="truncate">Log in</span>
                </.button>
              <% else %>
                <div class="ml-auto flex items-center space-x-2">
                  <.button
                    size="sm"
                    color="invisible"
                    navigate={~p"/coming-soon"}
                    class="truncate flex items-center space-x-1"
                  >
                    <.icon name="hero-trophy" class="size-4" />
                    <span class="truncate">My tournaments</span>
                  </.button>
                  <.dropdown_menu id="nav-dropdown" class="text-slate-900">
                    <.dropdown_menu_trigger>
                      <.button>
                        <div class="rounded-full size-6 bg-white flex">
                          <.icon name="hero-user-circle" class="size-6" />
                        </div>
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

      <main class="h-full">
        {render_slot(@inner_block)}
      </main>
    </div>

    <.flash_group flash={@flash} />
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

  def footer(assigns) do
    ~H"""
    <div class="bg-[#011108] bg-linear-to-b from-[#052e16] to-[#011108] border-t-4 border-green-700 text-white">
      <div class="container mx-auto p-4">
        <div class="grid grid-cols-1 md:grid-cols-4">
          <div>
            <p class="font-bold text-lg">What is Oregon Pinball?</p>
            <ul>
              <li>
                <.button
                  navigate={~p"/f/about/us"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  About us
                </.button>
              </li>
              <li>
                <.button
                  navigate={~p"/f/about/board"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  Our board
                </.button>
              </li>
            </ul>
          </div>

          <div>
            <p class="font-bold text-lg">Play</p>
            <ul>
              <li>
                <.button
                  navigate={~p"/tournaments"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  View events
                </.button>
              </li>
              <li>
                <.button
                  navigate={~p"/f/rules/code-of-conduct"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  Code of Conduct
                </.button>
              </li>
              <li>
                <.button
                  navigate={~p"/f/rules/playing"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  Rules
                </.button>
              </li>
            </ul>
          </div>

          <ul class="">
            <p class="font-bold text-lg">Host</p>
            <ul>
              <li>
                <.button
                  navigate={~p"/f/how-tos/host-a-certified-event"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  Submit an event
                </.button>
              </li>
              <li>
                <.button
                  navigate={~p"/f/rules/code-of-conduct"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  Code of Conduct
                </.button>
              </li>
              <li>
                <.button
                  navigate={~p"/f/rules/hosting"}
                  color="invisible"
                  class="hover:text-slate-900 transition-all"
                >
                  Rules
                </.button>
              </li>
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
