require IEx

defmodule DebounceAndThrottle.Debounce do
  @server DebounceAndThrottle.Server

  def send(pid, message, key, delay) do
    {:ok, GenServer.call(@server, {:send_debounced, {pid, message, key, delay}})}
  end

  def call(fun, key, delay) when is_function(fun) do
    {:ok, GenServer.call(@server, {:call_debounced, {fun, key, delay}})}
  end

  def apply(module, fun, args, key, delay) do
    {:ok, GenServer.call(@server, {:apply_debounced, {module, fun, args, key, delay}})}
  end
end
