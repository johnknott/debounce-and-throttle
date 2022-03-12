require IEx

defmodule DebounceAndThrottle.Throttle do
  @moduledoc """
  This module implements the Throttle API.
  """
  @server DebounceAndThrottle.Server

  def send(pid, message, key, delay) do
    {:ok, GenServer.call(@server, {:send_throttled, {pid, message, key, delay}})}
  end

  def call(func, key, delay) do
    {:ok, GenServer.call(@server, {:call_throttled, {func, key, delay}})}
  end

  def apply(module, fun, args, key, delay) do
    {:ok, GenServer.call(@server, {:apply_throttled, {module, fun, args, key, delay}})}
  end
end
