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

  ## GenServer
  def handle_call({:create_or_update, {game_code, players}}, _from, _state) do
      Logger.debug "GenServer handling: Create or update game"
      {:reply, :ok, :ets.insert(:games, {game_code, players})}
  end
  def handle_call({:get, game_id}, _from, state) do
      Logger.debug "GenServer handling: Lookup game"
      {:reply, :ets.lookup(:games, game_id), state}
  end
end
