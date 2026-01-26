# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :op, :scopes,
  user: [
    default: true,
    module: OP.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: OP.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :op,
  namespace: OP,
  ecto_repos: [OP.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :op, OPWeb.Endpoint,
  # The `host` and `port` determine what gets written into externally-facing
  # URLs, such as what gets written into an email.  Anytime an absolute
  # path for a URL is needed, it uses these values.
  #
  # You will need to set these to "normal" values like 80/443 if you're using a reverse proxy
  # and want the emailed URLs to be clickable.
  #
  url: [
    host: System.get_env("EXTERNAL_HOSTNAME") || "localhost",
    port: System.get_env("EXTERNAL_PORT") || "4000"
  ],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: OPWeb.ErrorHTML, json: OPWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OP.PubSub,
  live_view: [signing_salt: "8gYyfCcQ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :op, OP.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  op: [
    args:
      ~w(js/app.js js/storybook.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=. --loader:.js=jsx --loader:.jsx=jsx --loader:.ts=ts --loader:.tsx=tsx),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  op: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Add ENV to Application so it can be accessed at runtime
# via Application.get_env(:op, :env)
config :op, :env, config_env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
