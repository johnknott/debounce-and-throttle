defmodule DebounceAndThrottle.Server do
  use GenServer
  require IEx
  require Logger

  # Client (API is in debounce.ex and throttle.ex)

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  # Server (callbacks)

  @impl true
  def init(_state) do
    :timer.send_interval(1000, :cleanup)
    {:ok, initial_state()}
  end

  @impl true
  def handle_call(:reset, _, state) do
    cancel_timers(state)
    {:reply, :ok, initial_state()}
  end

  @impl true
  def handle_call({:send_debounced, {pid, message, key, delay}}, _, state) do
    old_key_state = state[:debounced][:send][key]
    {timer_ref, scheduled_at, count} = set_timer(old_key_state, {:send_fun, pid, message, key}, delay)
    key_state = debounced_key_state(timer_ref, scheduled_at, count, %{pid: pid, message: message})
    {:reply, key_state, add_fun_state(state, :debounced, :send, key, key_state)}
  end

  @impl true
  def handle_call({:call_debounced, {fun, key, delay}}, _, state) do
    old_key_state = state[:debounced][:call][key]
    {timer_ref, scheduled_at, count} = set_timer(old_key_state, {:call_fun, fun, key}, delay)
    key_state = debounced_key_state(timer_ref, scheduled_at, count, %{fun: fun})
    {:reply, key_state, add_fun_state(state, :debounced, :call, key, key_state)}
  end

  @impl true
  def handle_call({:apply_debounced, {module, fun, args, key, delay}}, _, state) do
    old_key_state = state[:debounced][:apply][key]
    {timer_ref, scheduled_at, count} = set_timer(old_key_state, {:apply_fun, module, fun, args, key}, delay)
    key_state = debounced_key_state(timer_ref, scheduled_at, count, %{module: module, fun: fun, args: args})
    {:reply, key_state, add_fun_state(state, :debounced, :apply, key, key_state)}
  end

  @impl true
  def handle_call({:send_throttled, {pid, message, key, delay}}, _, state) do
    old_key_state = state[:throttled][:send][key]
    key_state = throttled_key_state(old_key_state, delay, %{pid: pid, message: message})
    if key_state[:status] == :executed, do: send(pid, message)
    {:reply, key_state, add_fun_state(state, :throttled, :send, key, key_state)}
  end

  @impl true
  def handle_call({:call_throttled, {fun, key, delay}}, _, state) do
    old_key_state = state[:throttled][:call][key]
    key_state = throttled_key_state(old_key_state, delay, %{fun: fun})
    if key_state[:status] == :executed, do: spawn(fun)
    {:reply, key_state, add_fun_state(state, :throttled, :call, key, key_state)}
  end

  @impl true
  def handle_call({:apply_throttled, {module, fun, args, key, delay}}, _, state) do
    old_key_state = state[:throttled][:apply][key]
    key_state = throttled_key_state(old_key_state, delay, %{module: module, fun: fun, args: args})
    if key_state[:status] == :executed, do: spawn(fn -> apply(module, fun, args) end)
    {:reply, key_state, add_fun_state(state, :throttled, :apply, key, key_state)}
  end

  @impl true
  def handle_info({:send_fun, pid, message, key}, state) do
    send(pid, message)
    {:noreply, remove_fun_state(state, :send, key)}
  end

  @impl true
  def handle_info({:call_fun, fun, key}, state) do
    spawn(fun)
    {:noreply, remove_fun_state(state, :call, key)}
  end

  @impl true
  def handle_info({:apply_fun, module, fun, args, key}, state) do
    spawn(fn -> apply(module, fun, args) end)
    {:noreply, remove_fun_state(state, :apply, key)}
  end

  @impl true
  def handle_info(:cleanup, state) do
    {:noreply, cleanup(state, [:call, :apply, :send])}
  end

  @impl true
  def handle_info(message, state) do
    Logger.debug("#{__MODULE__}: Unknown message: #{inspect(message)}")
    {:noreply, state}
  end

  # Helpers

  def initial_state() do
    sca = %{send: %{}, call: %{}, apply: %{}}
    %{debounced: sca, throttled: sca}
  end

  def cleanup(state, types) do
    Enum.reduce(types, state, fn type, new_state ->
      filtered =
        :maps.filter(
          fn _, v -> v[:throttled_until] > System.monotonic_time(:millisecond) end,
          state[:throttled][type]
        )

      put_in(new_state, [:throttled, type], filtered)
    end)
  end

  defp cancel_timers(state) do
    for type <- [:apply, :call, :send] do
      get_in(state, [:debounced, type]) |> Map.values() |> Enum.each(fn x -> Process.cancel_timer(x.timer_ref) end)
    end
  end

  defp run_at(delay), do: DateTime.add(DateTime.utc_now(), delay, :millisecond)

  defp set_timer(%{timer_ref: timer_ref, debounced_count: debounced_count}, message, delay) do
    Process.cancel_timer(timer_ref)
    {Process.send_after(self(), message, delay), run_at(delay), debounced_count + 1}
  end

  defp set_timer(nil, message, delay), do: {Process.send_after(self(), message, delay), run_at(delay), 1}

  defp add_fun_state(state, ns, type, key, key_state), do: put_in(state, [ns, type, key], key_state)

  defp remove_fun_state(state, type, key), do: pop_in(state, [:debounced, type, key]) |> elem(1)

  defp debounced_key_state(timer_ref, scheduled_at, debounced_count, extra_data) do
    %{
      timer_ref: timer_ref,
      scheduled_at: scheduled_at,
      debounced_count: debounced_count,
      extra_data: extra_data
    }
  end

  defp throttled_key_state(old_key_state, delay, extra_data) do
    now = System.monotonic_time(:millisecond)

    case old_key_state[:throttled_until] do
      throttled_until when throttled_until == nil or now > throttled_until ->
        # Not throttled, or was throttled but now expired
        %{
          status: :executed,
          throttled_until: now + delay,
          throttled_until_utc: DateTime.add(DateTime.utc_now(), delay, :millisecond),
          throttled_count: 0,
          extra_data: extra_data
        }

      _ ->
        # Throttled
        Map.update(%{old_key_state | status: :throttled}, :throttled_count, 0, fn old_count ->
          old_count + 1
        end)
    end
  end
end
