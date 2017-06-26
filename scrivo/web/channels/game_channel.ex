defmodule Scrivo.GameChannel do
  use Scrivo.Web, :channel

  alias Scrivo.Presence
  alias Scrivo.GameServer
  alias Scrivo.GameCodeGenerator

  require Logger

  def join("game:main", _params, socket) do
      Logger.debug "Joined main lobby!"
      {:ok, socket}
  end

  def join("game:" <> game_code, _params, socket) do
      Logger.debug "Joined game " <> game_code
      game = GameServer.get(game_code) |> tl
      send(self(), :presence_update)
      {:ok, game, socket}
  end

  def handle_info(:presence_update, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_in("new:game", _params, socket) do
      new_game_code = GameCodeGenerator.code_of_length(8)
      GameServer.create_or_update(new_game_code)
      game = %{game_code: new_game_code, players: []}
      {:reply, {:ok, game}, socket}
  end

  def handle_in("new:player", params, socket) do
    "game:" <> game_code = socket.topic
    player_name = params["name"]
    GameServer.register_player(game_code, player_name)
    broadcast! socket, "new:player", %{
      name: player_name
    }
    {:reply, {:ok, %{name: player_name}}, socket}
  end
end
