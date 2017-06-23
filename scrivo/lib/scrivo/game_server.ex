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

  def register_player(game_code, player_name) do
      Logger.debug "Register player"
      GenServer.call(__MODULE__, {:register_player, game_code, player_name})
  end

  ## GenServer
  def handle_call({:create_or_update, game_code}, _from, _state) do
      Logger.debug "GenServer handling: Create or update game"
      {:reply, :ok, :ets.insert(:games, {game_code, {}})}
  end
  def handle_call({:get, game_code}, _from, state) do
      Logger.debug "GenServer handling: Lookup game"
      {:reply, :ets.lookup(:games, game_code), state}
  end
  def handle_call({:register_player, game_code, player_name}, _from, _state) do
      Logger.debug "GenServer handling: Create or update game"
      [{game_code, players}] = :ets.lookup(:games, game_code)
      players = Tuple.append(players, player_name)
      :ets.insert(:games, {game_code, players})
      {:reply, :ok, %{"name": player_name}}
  end

  def handle_info(_msg, state) do
      {:noreply, state}
  end
end
