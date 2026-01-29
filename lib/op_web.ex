defmodule OPWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use OPWeb, :controller
      use OPWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: OPWeb.Gettext

      import Plug.Conn

      def is_system_admin?(%OP.Accounts.Scope{} = scope) do
        scope.role == :system_admin
      end

      def is_system_admin?(_), do: false

      def is_admin?(%OP.Accounts.Scope{} = scope), do: scope.role in [:system_admin, :td]
      def is_admin?(_), do: false

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())

      def is_system_admin?(%OP.Accounts.Scope{} = scope) do
        scope.role == :system_admin
      end

      def is_system_admin?(_), do: false
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: OPWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import OPWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias OPWeb.Layouts
      alias OPWeb.Landing
      alias OPWeb.Fir
      alias OPWeb.Rankings

      def is_admin?(%OP.Accounts.Scope{} = scope), do: scope.role in [:system_admin, :td]
      def is_admin?(_), do: false

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: OPWeb.Endpoint,
        router: OPWeb.Router,
        statics: OPWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
