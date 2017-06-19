defmodule Scrivo.GameChannel do
  use Scrivo.Web, :channel

  alias Scrivo.GameServer
  alias Scrivo.GameCodeGenerator

  require Logger

  def join("game:main", _params, socket) do
      Logger.debug "Joined lobby!"
      {:ok, socket}
  end

  # def join("game:g:" <> game_code, _params, socket) do
  #     game = GameServer.call(__MODULE__, {:get, game_code}) |> tl
  #     {:ok, %{ game: game }, socket}
  # end

  def handle_in("new:game", _params, socket) do
      new_game_code = GameCodeGenerator.code_of_length(8)
      game = {new_game_code, {}}
      GameServer.create_or_update(game)
      {:reply, {:ok, %{game_code: new_game_code}}, socket}
  end

  def handle_in("new:player", params, socket) do
    player_name = params["player_name"]

    # GameServer.add(player_name)

    broadcast! socket, "new:player", %{
      player_name: player_name
    }

    {:noreply, socket}
  end
end
