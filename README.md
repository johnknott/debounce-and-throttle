# DebounceAndThrottle

[![Hex version badge](https://img.shields.io/hexpm/v/debounce_and_throttle.svg)](https://hex.pm/packages/debounce_and_throttle)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/johnknott/debounce-and-throttle/blob/master/LICENSE.md)
[![Code coverage badge](https://img.shields.io/codecov/c/github/johnknott/debounce-and-throttle/badge.svg)](https://app.codecov.io/gh/johnknott/debounce-and-throttle)
[![Github Workflow](https://img.shields.io/github/workflow/status/johnknott/debounce-and-throttle/Elixir%20CI?logo=GitHub)](https://github.com/johnknott/debounce-and-throttle/actions/workflows/elixir.yml)

DebounceAndThrottle is a simple library to allow to *debounce* or *throttle* function calls or message sending.

The following page explains throttling and debouncing quite well, albeit from a javascript perspective.

[https://css-tricks.com/debouncing-throttling-explained-examples/]

Examples can be found below and full documentation can be found at [hexdocs.pm](https://hexdocs.pm/debounce_and_throttle/api-reference.html).

## Installation

The package can be installed by adding `debounce_and_throttle` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:debounce_and_throttle, "~> 0.9.0"}
  ]
end
```

## Setup

### Setup with a Supervision Tree, perhaps in a Phoenix project

Add `DebounceAndThrottle.Server` to your Supervision tree in `lib/<application_name>/application.ex`

```elixir
children = [DebounceAndThrottle.Server, ...]
```

### Setup without a Supervision Tree, perhaps in a standalone script

```elixir
DebounceAndThrottle.Server.start_link([])
```

## Usage

Alias Debounce and Throttle if you want to keep things terse.

```elixir
alias DebounceAndThrottle.{Debounce, Throttle}
```

### Debounce

This anonymous function will be called after 5 seconds, but only if this method wasnt called in the interim with the same `key`

```elixir
Debounce.call(fn -> IO.puts("Hey there!") end, "some-key", 5_000)
```

This module, function and arguments will be called after 5 seconds, but only if this method wasnt called in the interim with the same `key`

```elixir
Debounce.apply(IO, :puts, ["Hey there!"], "some-key", 5_000)
```

This message will be sent after 5 seconds, but only if this method wasnt called in the interim with the same `key`

```elixir
Debounce.send(fn -> IO.puts("Hey there!") end, "some-key", 5_000)
```

Returns the state - the current list of debounced functions. Useful for debugging.

```elixir
iex> Debounce.state
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
```

### Throttle

This anonymous function will be called straight away, but only if this method wasnt called in the last 5 seconds with the same `key`

```elixir
Throttle.call(fn -> IO.puts("Hey there!") end, "some-key", 5_000)
```

This module, function and arguments will be called straight away, but only if this method wasnt called in last 5 seconds with the same `key`

```elixir
Throttle.apply(IO, :puts, ["Hey there!"], "some-key", 5_000)
```

This message will be sent straight away, but only if this method wasnt called in the last 5 seconds with the same `key`

```elixir
Throttle.send(fn -> IO.puts("Hey there!") end, "some-key", 5_000)
```

Returns the state - the current list of throttled functions. Useful for debugging.

```elixir
iex> Throttle.state
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
```

## Notes

### Choice of key

Your choice of what to use as the `key` depends on the granularity you want to throttle or debounce things.

So, bad example - if you wanted to throttle a `send_sms` function - if you used `send_sms` as the key it would throttle the function for every user in the system which is probably not what you want. So you might use something like `sms-#{user_id}` as the key to throttle it per user.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details
