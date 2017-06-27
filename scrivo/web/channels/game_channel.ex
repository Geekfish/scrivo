defmodule Scrivo.GameChannel do
  use Scrivo.Web, :channel
  alias Scrivo.Presence
  alias Scrivo.GameServer
  alias Scrivo.GameCodeGenerator
  alias Scrivo.Player
  require Logger

  def join("game:main", _params, socket) do
    Logger.debug "Joined main lobby!"
    {:ok, socket}
  end

  def join("game:" <> game_code, _params, socket) do
    Logger.debug "Joined game " <> game_code

    player = Player.create(socket.assigns.user_ref)

    GameServer.add_player game_code, player
    game = GameServer.get(game_code) |> tl

    send self(), :presence_update
    broadcast! socket, "player:update", player

    {:ok, %{game: game, player: player}, socket}
  end


  def handle_info(:presence_update, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} =
      Presence.track(
        socket, socket.assigns.user_ref,
        %{online_at: inspect(System.system_time(:seconds))})

    {:noreply, socket}
  end


  def handle_in("new:game", _params, socket) do
    new_game_code = GameCodeGenerator.code_of_length(8)
    GameServer.create_or_update new_game_code
    game = %{game_code: new_game_code, players: %{}}

    {:reply, {:ok, game}, socket}
  end

  def handle_in("player:update", params, socket) do
    "game:" <> game_code = socket.topic
    player_name = params["name"]

    {:ok, player} =
        GameServer.update_name(
            game_code, socket.assigns.user_ref, player_name)

    broadcast! socket, "player:update", player

    {:reply, {:ok, player}, socket}
  end
end
