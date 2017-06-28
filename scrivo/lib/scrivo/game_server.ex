defmodule Scrivo.GameServer do
  use GenServer
  require Logger

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

  def create_or_update(game) do
      Logger.debug "Create or update game"
      GenServer.call(__MODULE__, {:create_or_update, game})
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

  ## GenServer
  def handle_call({:create_or_update, game}, _from, _state) do
      Logger.debug "GenServer handling: Create or update game"
      {:reply, :ok, :ets.insert(:games, game)}
  end
  def handle_call({:get, game_code}, _from, state) do
      Logger.debug "GenServer handling: Lookup game"
      {:reply, :ets.lookup(:games, game_code), state}
  end
  def handle_call({:update_name, game_code, ref, name}, _from, state) do
      Logger.debug "GenServer handling: Update player name"
      [{game_code, players}] = :ets.lookup(:games, game_code)
      players = put_in players[ref].name, name
      :ets.insert(:games, {game_code, players})
      {:reply, {:ok, players[ref]}, state}
  end
  def handle_call({:add_player, game_code, player}, _from, _state) do
      Logger.debug "GenServer handling: add player"
      [{game_code, players}] = :ets.lookup(:games, game_code)
      players = Map.put_new players, player.ref, player
      :ets.insert(:games, {game_code, players})
      {:reply, :ok, player}
  end

  def handle_info(_msg, state) do
      {:noreply, state}
  end
end
