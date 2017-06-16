defmodule Scrivo.GameChannel do
  use Scrivo.Web, :channel

  alias Scivo.GameServer

  def join("game:" <> game_id, _params, socket) do
      game = GameServer.call(__MODULE__, {:get, game_id}) |> tl
      {:ok, %{ game: game }, socket}
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
