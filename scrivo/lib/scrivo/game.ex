defmodule Scrivo.Game do
    require Logger

    @derive [Poison.Encoder]
    @enforce_keys [:game_code, :players]
    defstruct [:game_code, :in_progress, :players, :current_player, :story]

    defp serialize_segments(stories) do
        stories
            |> Enum.map(fn story -> [story.ref, story.text] end)
    end

    defp deserialize_segments(stories) do
        stories
            |> Enum.map(fn [ref, text] -> %{ref: ref, text: text} end)
    end

    def as_tuple(game) do
        {
            game.game_code,
            game.in_progress,
            game.players,
            game.current_player,
            game.story |> serialize_segments
        }
    end

    def from_tuple({game_code, in_progress, players, current_player, story}) do
        %Scrivo.Game{
            game_code: game_code,
            in_progress: in_progress,
            players: players,
            current_player: current_player,
            story: story |> deserialize_segments
        }
    end

    def create(game_code) do
        %Scrivo.Game{
            game_code: game_code,
            in_progress: false,
            players: %{},
            current_player: nil,
            story: [],
        }
    end

    def add_player(game, player) do
      %Scrivo.Game{
          game | players: (Map.put_new game.players, player.ref, player)
      }
    end

    def update_player_name(game, ref, name) do
      put_in game.players[ref].name, name
    end

    defp find_item_with_minimum_occurence(items) do
        # TODO: rewrite this, there must be a way to order a list
        # by the value of a specific key?
        items
            |> Enum.reduce(
                %{}, fn(ref, acc) -> Map.update(acc, ref, 1, &(&1 + 1)) end)
            |> Enum.map(&Tuple.to_list/1)
            |> Enum.reduce(
                fn counter, min_counter ->
                    if  tl(counter) < tl(min_counter) do
                        counter
                    else min_counter end
                end)
            |> hd
    end

    def get_next_player(game) do
        refs = game.players |> Map.keys
        story_refs = game.story |> Enum.map(&(Map.fetch! &1, :ref))
        not_played_yet = refs -- story_refs

        Logger.debug("Refs:")
        Logger.debug(refs)
        Logger.debug("Story refs:")
        Logger.debug(story_refs)
        Logger.debug("Not played yet:")
        Logger.debug(not_played_yet)

        next_player =
            if length(not_played_yet) > 0 do
                not_played_yet |> Enum.random
            else
                story_refs |> find_item_with_minimum_occurence
            end
        Logger.debug("Next player:")
        Logger.debug(next_player)
        next_player
    end

    def submit_story_segment(game, player_ref, story_segment) do
      game = %Scrivo.Game{
          game | story: game.story ++ [%{ref: player_ref, text: story_segment}]
      }
      %Scrivo.Game{
          game | current_player: get_next_player(game)
      }
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
