require IEx

defmodule DebounceAndThrottle.Debounce do
  defstruct([:timer_ref, :scheduled_at, :debounced_count, :extra_data])
  alias DebounceAndThrottle.Debounce

  @type t :: %Debounce{
          timer_ref: reference(),
          scheduled_at: DateTime.t(),
          debounced_count: non_neg_integer(),
          extra_data: map()
        }

  @moduledoc """
  This module implements the Debounce API.
  """
  @server DebounceAndThrottle.Server

  @doc """
  Sends a `message` to a given `pid`, but only after `period` has passed without any more calls to this function with the same `key`

  Returns `{:ok, %Debounce{}}`.
  """
  @spec send(pid() | atom(), term(), String.t(), non_neg_integer()) :: {:ok, Debounce.t()}
  def send(pid, message, key, period) do
    result = GenServer.call(@server, {:send_debounced, {pid, message, key, period}})
    {:ok, result}
  end

  @doc """
  Calls a `fun` but only after `period` has passed without any more calls to this function with the same `key`

  Returns `{:ok, %Debounce{}}`.
  """
  @spec call(fun(), String.t(), non_neg_integer()) :: {:ok, Debounce.t()}
  def call(fun, key, period) when is_function(fun) do
    result = GenServer.call(@server, {:call_debounced, {fun, key, period}})
    {:ok, result}
  end

  @doc """
  Calls a `fun` but only after `period` has passed without any more calls to this function with the same `key`

  Returns `{:ok, %Debounce{}}`.
  """
  @spec apply(module, fun :: atom(), [any], String.t(), non_neg_integer()) :: {:ok, Debounce.t()}
  def apply(module, fun, args, key, period) do
    result = GenServer.call(@server, {:apply_debounced, {module, fun, args, key, period}})
    {:ok, result}
  end

  @doc """
  Returns the state - the current list of debounced functions. Useful for debugging.

  Returns something like:
  %{
    apply: %{},
    call: %{
      "say_hey" => %DebounceAndThrottle.Debounce{
        debounced_count: 1,
        extra_data: %{fun: #Function<45.65746770/0 in :erl_eval.expr/5>},
        scheduled_at: ~U[2022-03-12 22:50:01.190171Z],
        timer_ref: #Reference<0.418177534.3850108929.259344>
      }
    },
    send: %{}
  }
  """
  @spec state() :: map()
  def state(), do: GenServer.call(@server, {:state, :debounced})
end
