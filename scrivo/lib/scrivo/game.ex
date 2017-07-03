defmodule Scrivo.Game do
    require Logger

    @derive [Poison.Encoder]
    @enforce_keys [:game_code, :players]
    defstruct [:game_code, :in_progress, :players]

    def as_tuple(game) do
        {game.game_code, game.in_progress, game.players}
    end

    def from_tuple({game_code, in_progress, players}) do
        %Scrivo.Game{game_code: game_code, in_progress: in_progress, players: players}
    end

    def create(game_code) do
        %Scrivo.Game{game_code: game_code, in_progress: false, players: %{}}
    end

    def add_player(game, player) do
      %Scrivo.Game{
          game | players: (Map.put_new game.players, player.ref, player)
      }
    end

    def update_player_name(game, ref, name) do
      put_in game.players[ref].name, name
    end

    def start(game) do
      %Scrivo.Game{
          game | in_progress: true
      }
    end
end
