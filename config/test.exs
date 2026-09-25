import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :jido_lab, JidoLab.Repo,
  database: Path.expand("../jido_lab_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :jido_lab, JidoLabWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7lg6v9RPfVmm9KSfQsVGwPbO9EtP/mAzQu/7gOFxyvnu6jItfiNgAGBLuT/6P5MZ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Keep hibernated test agents out of priv/.
config :jido_lab, :agent_storage, Path.join(System.tmp_dir!(), "jido_lab_test_agents")
