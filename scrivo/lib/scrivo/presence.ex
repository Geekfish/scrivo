defmodule Scrivo.Presence do
  use Phoenix.Presence, otp_app: :my_app,
                        pubsub_server: Scrivo.PubSub
end
