defmodule Scrivo.GameServer do
  use GenServer
  require Logger

  ## Client

  def start_link do
    {:ok, pid} = GenServer.start_link(__MODULE__, [])
    GenServer.call(pid, :create_tables)
    {:ok, pid}
  end

  def log(uid) do
    GenServer.call(__MODULE__, {:log, uid})
  end

  ## Server
  def handle_call(:create_tables, _from, _state) do
      {:reply, :ok, :ets.new(:games, [:set, :public, :named_table])}
  end
  def handle_call({:create_or_update, {game_code, players}}, _from, _state) do
      {:reply, :ok, :ets.insert(:games, {game_code, players})}
  end
  def handle_call({:get, game_id}, _from, _state) do
      {:reply, :ok, :ets.lookup(:games, game_id)}
  end

end
