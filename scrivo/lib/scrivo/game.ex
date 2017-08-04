defmodule Scrivo.Game do
    require Logger

    @derive [Poison.Encoder]
    @enforce_keys [:game_code, :players]
    defstruct [:game_code, :in_progress, :players, :current_player]

    def as_tuple(game) do
        {game.game_code, game.in_progress, game.players, game.current_player}
    end

    def from_tuple({game_code, in_progress, players, current_player}) do
        %Scrivo.Game{game_code: game_code, in_progress: in_progress, players: players, current_player: current_player}
    end

    def create(game_code) do
        %Scrivo.Game{game_code: game_code, in_progress: false, players: %{}, current_player: nil}
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
      current_player = game.players |> Map.keys |> Enum.random
      Logger.debug "First Player: #{current_player}"
      %Scrivo.Game{
          game | in_progress: true,
                 current_player: current_player
      }
    end
end
