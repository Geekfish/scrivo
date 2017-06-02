# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :scrivo,
  ecto_repos: [Scrivo.Repo]

# Configures the endpoint
config :scrivo, Scrivo.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YoVPwrsAUywCrt4l2U6sJmSJAzx0yg+LNMZTw6Y0r6Gh3etCQa9mfHSQMsUBviA+",
  render_errors: [view: Scrivo.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Scrivo.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
