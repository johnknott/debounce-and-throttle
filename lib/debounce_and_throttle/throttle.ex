require IEx

defmodule DebounceAndThrottle.Throttle do
  alias DebounceAndThrottle.Throttle
  defstruct([:status, :throttled_until, :throttled_until_utc, :throttled_count, :extra_data])

  @moduledoc """
  This module implements the Throttle API.
  """
  @server DebounceAndThrottle.Server

  @doc """
  Sends a `message` to a given `pid`, but only once during `period` per `key`

  Returns `{:ok, %Throttle{}}`.
  """
  def send(pid, message, key, period) do
    result = GenServer.call(@server, {:send_throttled, {pid, message, key, period}})
    {:ok, struct(Throttle, result)}
  end

  @doc """
  Calls a `fun`, but only once during `period` per `key`

  Returns `{:ok, %Throttle{}}`.
  """
  def call(fun, key, period) do
    result = GenServer.call(@server, {:call_throttled, {fun, key, period}})
    {:ok, struct(Throttle, result)}
  end

  @doc """
  Calls a `func`, but only once during `period` per `key`

  Returns `{:ok, %Throttle{}}`.
  """
  def apply(module, fun, args, key, period) do
    result = GenServer.call(@server, {:apply_throttled, {module, fun, args, key, period}})
    {:ok, struct(Throttle, result)}
  end
end
