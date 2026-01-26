defmodule OPWeb.Router do
  use OPWeb, :router

  import OPWeb.UserAuth
  import PhoenixStorybook.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OPWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    storybook_assets()
  end

  #   _____     _     _ _
  # | ___ \    | |   | (_)
  # | |_/ /   _| |__ | |_  ___
  # |  __/ | | | '_ \| | |/ __|
  # | |  | |_| | |_) | | | (__
  # \_|   \__,_|_.__/|_|_|\___|
  #
  # Viewable by guests/non-authenticated users
  scope "/", OPWeb do
    # Use the default browser pipeline, which notably
    # does NOT require the user to be authenticated.  This is
    # the scope for public routes that a non-authenticated user
    # and authenticated user can access.
    pipe_through :browser

    get "/", PageController, :home

    get "/leagues/:slug", LeagueController, :show
    get "/seasons/:slug", SeasonController, :show
    get "/players/:slug", PlayerController, :show
    get "/locations", LocationController, :index
    get "/locations/:slug", LocationController, :show

    #
    # Fir CMS
    #
    get "/f/*slugs", FirController, :content

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete

    # TODO: Remove later, developer testing route for rendering
    # React components based on Phoenix-rendered templates
    get "/react", PageController, :react

    # Setup `assigns.current_scope` for all sessions, even if it
    # is `nil`, to keep a standard interface with back-end queries.
    live_session :current_user,
      on_mount: [{OPWeb.UserAuth, :mount_current_scope}] do
      live "/tournaments", TournamentLive.Index, :index
      live "/tournaments/:slug", TournamentLive.Show, :show

      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    # Storybook
    live_storybook("/storybook", backend_module: OPWeb.Storybook)
  end

  #   ___  _   _ _____ _   _  _   _
  #  / _ \| | | |_   _| | | || \ | |
  # / /_\ \ | | | | | | |_| ||  \| |
  # |  _  | | | | | | |  _  || . ` |
  # | | | | |_| | | | | | | || |\  |
  # \_| |_/\___/  \_/ \_| |_/\_| \_/
  #
  # Authenticated routes (requires user)
  scope "/", OPWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/users/update-password", UserSessionController, :update_password

    # Setup `assigns.current_scope` for all authenticated sessions,
    # this requires a valid scope.
    live_session :require_authenticated_user,
      on_mount: [{OPWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Matchplay import
      live "/import", ImportLive, :index
    end
  end

  #   ___ _________  ________ _   _
  #  / _ \|  _  \  \/  |_   _| \ | |
  # / /_\ \ | | | .  . | | | |  \| |
  # |  _  | | | | |\/| | | | | . ` |
  # | | | | |/ /| |  | |_| |_| |\  |
  # \_| |_/___/ \_|  |_/\___/\_| \_/
  #
  # Requires system admin users
  scope "/admin", OPWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_system_admin,
      on_mount: [{OPWeb.UserAuth, :require_system_admin}] do
      live "/dashboard", AdminLive.Dashboard, :index

      live "/tournaments", TournamentLive.Index, :index
      live "/tournaments/new", TournamentLive.Index, :new
      live "/tournaments/:id/edit", TournamentLive.Index, :edit
      live "/tournaments/:id", TournamentLive.Show, :show

      live "/leagues", LeagueLive.Index, :index
      live "/leagues/new", LeagueLive.Form, :new
      live "/leagues/:id/edit", LeagueLive.Form, :edit
      live "/leagues/:id", LeagueLive.Show, :show

      live "/seasons", SeasonLive.Index, :index
      live "/seasons/new", SeasonLive.Form, :new
      live "/seasons/:id/edit", SeasonLive.Form, :edit
      live "/seasons/:id", SeasonLive.Show, :show

      live "/players", PlayerLive.Index, :index
      live "/players/new", PlayerLive.Form, :new
      live "/players/:slug/edit", PlayerLive.Form, :edit

      live "/locations", LocationLive.Index, :index
      live "/locations/new", LocationLive.Form, :new
      live "/locations/:slug/edit", LocationLive.Form, :edit

      live "/users", UserLive.Index, :index
      live "/users/:id/edit", UserLive.Form, :edit
    end
  end

  scope "/admin", OPWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_system_admin_fir,
      on_mount: [{OPWeb.UserAuth, :require_system_admin}] do
      live "/fir", FirLive.Manager, :index
    end
  end

  ## Development
  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:op, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OPWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
