defmodule Scrivo.GameServer do
  use GenServer
  require Logger

  alias Scrivo.Game

  ## External API
  def start_link do
      Logger.debug "Link to ETS started"
      GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def log(uid) do
    GenServer.call(__MODULE__, {:log, uid})
  end

  def init(:ok) do
      Logger.debug "Init games table"
      {:ok, :ets.new(:games, [:set, :public, :named_table])}
  end

  def create(game_code) do
      Logger.debug "Create or update game"
      GenServer.call(__MODULE__, {:create, game_code})
  end

  def get(game_code) do
      Logger.debug "Fetch a game"
      GenServer.call(__MODULE__, {:get, game_code})
  end

  def update_name(game_code, ref, player_name) do
      Logger.debug "Update player name"
      GenServer.call(__MODULE__, {:update_name, game_code, ref, player_name})
  end

  def add_player(game_code, player) do
      Logger.debug "Add player"
      GenServer.call(__MODULE__, {:add_player, game_code, player})
  end

  def start(game_code) do
      Logger.debug "Starting game"
      GenServer.call(__MODULE__, {:start, game_code})
  end

  ## GenServer
  defp fetch_game(game_code) do
      :ets.lookup(:games, game_code) |> hd |> Game.from_tuple
  end

  defp store_game(game) do
      :ets.insert(:games, Game.as_tuple game)
  end

  def handle_call({:create, game_code}, _from, state) do
      Logger.debug "GenServer handling: Create or update game"
      game = Game.create game_code
      store_game game
      {:reply, {:ok, game}, state}
  end
  def handle_call({:get, game_code}, _from, state) do
      Logger.debug "GenServer handling: Lookup game"
      {:reply, fetch_game(game_code), state}
  end
  def handle_call({:update_name, game_code, ref, name}, _from, state) do
      Logger.debug "GenServer handling: Update player name"
      game =
          game_code
          |> fetch_game
          |> Game.update_player_name(ref, name)

      store_game game
      {:reply, {:ok, game.players[ref]}, state}
  end
  def handle_call({:add_player, game_code, player}, _from, _state) do
      Logger.debug "GenServer handling: add player"
      game =
          game_code
          |> fetch_game
          |> Game.add_player(player)

      store_game game
      {:reply, :ok, player}
  end
  def handle_cast({:start, game_code}, _from, state) do
      Logger.debug "GenServer handling: start game"
      game =
          game_code
          |> fetch_game
          |> Game.start

      store_game game
      {:reply, :ok, state}
  end

  def handle_info(_msg, state) do
      {:noreply, state}
  end
end
