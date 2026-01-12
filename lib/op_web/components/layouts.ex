defmodule OPWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use OPWeb, :html

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

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.sheet id="mobile-nav">
      <.nav_buttons current_scope={@current_scope} is_mobile?={true} />
    </.sheet>

    <nav class="sticky top-0 bg-white border-b-2 p-2">
      <div class="container mx-auto">
        <.nav_buttons current_scope={@current_scope} />
      </div>
    </nav>

    <main class="container mx-auto">
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
        else: assigns.class <> " hidden md:flex items-center"

    assigns = Map.put(assigns, :class, class)

    ~H"""
    <ul class={[@class]}>
      <li class="grow">
        <.button navigate={~p"/"} color="invisible">
          <span class="font-semibold">Open Pinball</span>
        </.button>
      </li>
      <%= if @current_scope do %>
        <li>
          {@current_scope.user.email}
        </li>
        <li :if={is_system_admin?(@current_scope)}>
          <.link href={~p"/admin/dashboard"}>Admin Dashboard</.link>
        </li>
        <li>
          <.link href={~p"/users/settings"}>Settings</.link>
        </li>
        <li>
          <.link href={~p"/users/log-out"} method="delete">Log out</.link>
        </li>
      <% else %>
        <li>
          <.button navigate={~p"/users/register"} color="invisible">Register</.button>
        </li>
        <li>
          <.button navigate={~p"/users/log-in"}>Log in</.button>
        </li>
      <% end %>
    </ul>

    <ul :if={!@is_mobile?} class="flex justify-end md:hidden">
      <li class="grow">
        <.link navigate={~p"/"}>
          <span class="font-semibold">Open Pinball</span>
        </.link>
      </li>
      <li class="">
        <.button phx-click={toggle("#mobile-nav")} color="invisible">
          <.icon name="hero-bars-3" class="size-6 text-black dark:text-white hover:cursor-pointer" />
        </.button>
      </li>
    </ul>
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
