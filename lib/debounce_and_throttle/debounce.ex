require IEx

defmodule DebounceAndThrottle.Debounce do
  alias DebounceAndThrottle.Debounce
  defstruct([:timer_ref, :scheduled_at, :debounced_count, :extra_data])

  @moduledoc """
  This module implements the Debounce API.
  """
  @server DebounceAndThrottle.Server

  @doc """
  Sends a `message` to a given `pid`, but only after `period` has passed without any more calls to this function with the same `key`

  Returns {:ok, %Debounce{}}.
  """
  def send(pid, message, key, period) do
    result = GenServer.call(@server, {:send_debounced, {pid, message, key, period}})
    {:ok, struct(Debounce, result)}
  end

  @doc """
  Calls a `fun` but only after `period` has passed without any more calls to this function with the same `key`

  Returns {:ok, %Debounce{}}.
  """
  def call(fun, key, period) when is_function(fun) do
    result = GenServer.call(@server, {:call_debounced, {fun, key, period}})
    {:ok, struct(Debounce, result)}
  end

  @doc """
  Calls a `fun` but only after `period` has passed without any more calls to this function with the same `key`

  Returns {:ok, %Debounce{}}.
  """
  def apply(module, fun, args, key, period) do
    result = GenServer.call(@server, {:apply_debounced, {module, fun, args, key, period}})
    {:ok, struct(Debounce, result)}
  end
end
