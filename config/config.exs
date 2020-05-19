# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :hangman_live,
  ecto_repos: [HangmanLive.Repo]
#  hangman_live_repos: [HangmangLive.Repo],

config :hangman_live, HangmanLive.Repo,
  database: "hangman_live_repo",
  username: "db_user",
  password: "db_password",
  hostname: "localhost"

# Configures the endpoint
config :hangman_live, HangmanLiveWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "TWrIM0BcSxuyDmuctiLRDWXVI4OMEXhC2rUzxh9sVbOPr9pHVEpo11SUe++zeOfX",
  render_errors: [view: HangmanLiveWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HangmanLive.PubSub,
  live_view: [signing_salt: "YISZJNLb"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
