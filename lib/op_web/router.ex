defmodule OPWeb.Router do
  alias OP.Leagues.Season
  use OPWeb, :router

  import OPWeb.UserAuth

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
  end

  ## Authenticated routes
  scope "/", OPWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{OPWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
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
