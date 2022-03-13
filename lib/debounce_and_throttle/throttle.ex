defmodule DebounceAndThrottle.Throttle do
  alias DebounceAndThrottle.Throttle
  defstruct([:status, :throttled_until, :throttled_until_utc, :throttled_count, :extra_data])

  @type t :: %Throttle{
          status: atom(),
          throttled_until: integer(),
          throttled_until_utc: DateTime.t(),
          throttled_count: non_neg_integer(),
          extra_data: map()
        }

  @moduledoc """
  This module implements the Throttle API.
  """
  @server DebounceAndThrottle.Server

  @doc """
  Sends a `message` to a given `pid`, but only once during `period` per `key`

  Returns `{:ok, %Throttle{}}`.
  """
  @spec send(pid() | atom(), term(), String.t(), non_neg_integer()) :: {:ok, Throttle.t()}
  def send(pid, message, key, period) do
    result = GenServer.call(@server, {:send_throttled, {pid, message, key, period}})
    {:ok, result}
  end

  @doc """
  Calls a `fun`, but only once during `period` per `key`

  Returns `{:ok, %Throttle{}}`.
  """
  @spec call(fun(), String.t(), non_neg_integer()) :: {:ok, Throttle.t()}
  def call(fun, key, period) do
    result = GenServer.call(@server, {:call_throttled, {fun, key, period}})
    {:ok, result}
  end

  @doc """
  Calls a `func`, but only once during `period` per `key`

  Returns `{:ok, %Throttle{}}`.
  """
  @spec apply(module, fun :: atom(), [any], String.t(), non_neg_integer()) :: {:ok, Throttle.t()}
  def apply(module, fun, args, key, period) do
    result = GenServer.call(@server, {:apply_throttled, {module, fun, args, key, period}})
    {:ok, result}
  end

  @doc """
  Returns the state - the current list of throttled functions. Useful for debugging.

  Returns something like:
  %{
    apply: %{},
    call: %{
      "say_hey" => %DebounceAndThrottle.Throttle{
        extra_data: %{fun: #Function<45.65746770/0 in :erl_eval.expr/5>},
        status: :executed,
        throttled_count: 0,
        throttled_until: -576460730743,
        throttled_until_utc: ~U[2022-03-12 22:47:39.829107Z]
      }
      ...
    },
    send: %{}
  }
  """
  @spec state() :: map()
  def state(), do: GenServer.call(@server, {:state, :throttled})
end
