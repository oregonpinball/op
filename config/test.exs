import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :op, OP.Repo,
  database: Path.expand("../op_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :op, OPWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "LmL/CBbF3Qa19/X5OMz4l6xogfnRYLcfAasg0Rw+yOB5DWZJ0xYrBIWGMj+Di1IB",
  server: false

# In test we don't send emails
config :op, OP.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure Req.Test for mocking HTTP requests in tests
config :op, :req_options, plug: {Req.Test, OP.Matchplay.Client}

# Configure a test API token for Matchplay tests
config :op, :matchplay_api_token, "test-api-token"

# Enable feature flags for tests
config :op, :feature_flags,
  registration_enabled: true,
  tournament_submission_enabled: true,
  tournaments_only: false
