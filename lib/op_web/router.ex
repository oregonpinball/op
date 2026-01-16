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

  scope "/", OPWeb do
    # Use the default browser pipeline, which notably
    # does NOT require the user to be authenticated.  This is
    # the scope for public routes that a non-authenticated user
    # and authenticated user can access.
    pipe_through :browser

    get "/", PageController, :home

    get "/tournaments", TournamentController, :index
    get "/leagues/:slug", LeagueController, :show
    get "/seasons/:slug", SeasonController, :show
    get "/players/:slug", PlayerController, :show
    get "/locations", LocationController, :index
    get "/locations/:slug", LocationController, :show

    # TODO: Remove later, developer testing route for rendering
    # React components based on Phoenix-rendered templates
    get "/react", PageController, :react

    # Authentication-based routes
    live_session :current_user,
      on_mount: [{OPWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete

    # Storybook
    live_storybook("/storybook", backend_module: OPWeb.Storybook)
  end

  ## Authenticated routes
  scope "/", OPWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{OPWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      # Matchplay import
      live "/import", ImportLive, :index
    end

    post "/users/update-password", UserSessionController, :update_password

    live_session :require_system_admin,
      on_mount: [{OPWeb.UserAuth, :require_system_admin}] do
      live "/admin/dashboard", AdminLive.Dashboard, :index
      live "/admin/locations", LocationLive.Index, :index
      live "/admin/locations/new", LocationLive.Form, :new
      live "/admin/locations/:slug/edit", LocationLive.Form, :edit
      live "/admin/players", PlayerLive.Index, :index
      live "/admin/players/new", PlayerLive.Form, :new
      live "/admin/players/:slug/edit", PlayerLive.Form, :edit
      live "/admin/users", UserLive.Admin.Index, :index
      live "/admin/users/:id/edit", UserLive.Admin.Form, :edit
    end
  end

  ## Admin routes
  scope "/admin", OPWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_admin,
      on_mount: [{OPWeb.UserAuth, :require_admin}] do
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
