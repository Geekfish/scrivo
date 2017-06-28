defmodule Scrivo.Game do
    @derive [Poison.Encoder]
    @enforce_keys [:game_code, :players]
    defstruct [:game_code, :players]

    def create(game_code) do
        %Scrivo.Game{game_code: game_code, players: %{}}
    end

    def as_tuple(game) do
        {game.game_code, game.players}
    end

    def from_enum({game_code, players}) do
        %Scrivo.Game{game_code: game_code, players: players}
    end
end
