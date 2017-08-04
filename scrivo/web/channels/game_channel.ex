defmodule Scrivo.GameChannel do
  use Scrivo.Web, :channel
  alias Scrivo.Presence
  alias Scrivo.GameServer
  alias Scrivo.GameCodeGenerator
  alias Scrivo.Player
  require Logger

  def join("game:main", _params, socket) do
    Logger.debug "Joined main lobby!"
    player = Player.create(socket.assigns.user_ref)
    {:ok, player, socket}
  end

  def join("game:" <> game_code, _params, socket) do
    Logger.debug "Joined game " <> game_code

    player = Player.create(socket.assigns.user_ref)
    GameServer.add_player game_code, player

    game = GameServer.get(game_code)

    send self(), {:presence_update, player}

    {:ok, game, socket}
  end


  def handle_info({:presence_update, player}, socket) do
    push socket, "presence_state", Presence.list(socket)
    {:ok, _} =
      Presence.track(
        socket, socket.assigns.user_ref,
        %{online_at: inspect(System.system_time(:seconds)), ref: player.ref})

    broadcast! socket, "player:update", player

    {:noreply, socket}
  end


  def handle_in("game:new", _params, socket) do
    new_game_code = GameCodeGenerator.code_of_length(8)
    {:ok, game} = GameServer.create(new_game_code)
    {:reply, {:ok, game}, socket}
  end

  def handle_in("game:start", _params, socket) do
    "game:" <> game_code = socket.topic
    {:ok, game} = GameServer.start(game_code)
    broadcast! socket, "game:start", game
    {:reply, :ok, socket}
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

  def handle_in("game:receive_input", params, socket) do
    current_input = params["text_input"]
    broadcast! socket, "game:receive_input", %{text_input: current_input}
    {:noreply, socket}

  end
end
