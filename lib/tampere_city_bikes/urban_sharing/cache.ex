defmodule TampereCityBikes.UrbanSharing.Cache do
  use GenServer
  require Logger

  @five_minutes_as_ms 1 * 60 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :ets.new(:cache, [:named_table, :public, read_concurrency: true, write_concurrency: true])
    Process.send_after(self(), :expire_cache, @five_minutes_as_ms)
    {:ok, []}
  end

  def write(key, value) do
    Logger.info("Writing new data to cache for key: #{key}")
    :ets.insert(:cache, {key, value, System.system_time(:millisecond)})
  end

  def read(key) do
    case :ets.lookup(:cache, key) do
      [] -> 
        Logger.warning("Cache miss for key: #{key}")
        {:error, :not_found}
      [{_key, value, timestamp}] -> 
        if System.system_time(:millisecond) - timestamp < @five_minutes_as_ms do
          Logger.debug("Cache hit for key: #{key}")
          {:ok, Jason.decode!(value, keys: :atoms)}
        else
          Logger.warning("Cache expired for key: #{key}")
          {:error, :expired}
        end
    end
  end

  def handle_info(:expire_cache, state) do
    current_time = System.system_time(:millisecond)
    
    expired_keys = :ets.foldl(fn ({key, _value, timestamp}, acc) ->
      if current_time - timestamp >= @five_minutes_as_ms do
        [key | acc]
      else
        acc
      end
    end, [], :cache)

    Enum.each(expired_keys, fn key ->
      :ets.delete(:cache, key)
    end)

    Logger.debug("Expired items removed from the cache.")

    # Reschedule to run again after given MS
    Process.send_after(self(), :expire_cache, @five_minutes_as_ms)

    {:noreply, state}
  end
end
