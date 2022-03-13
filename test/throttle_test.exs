defmodule ThrottleTest do
  use ExUnit.Case
  alias DebounceAndThrottle.{Throttle, Server}

  doctest Throttle

  setup do
    Server.reset()
    :ok
  end

  test "Throttle.send sends and then throttles a message correctly" do
    delay = 5_000
    should_be_throttled_until = DateTime.add(DateTime.utc_now(), delay, :millisecond)

    this = self()

    assert {:ok,
            %{
              throttled_count: 0,
              status: :executed,
              extra_data: %{message: :some_message, pid: ^this},
              throttled_until: until,
              throttled_until_utc: until_utc
            }} = Throttle.send(self(), :some_message, "Throttle.send.1", delay)

    assert(is_number(until))
    assert(is_struct(until_utc))
    assert(Time.diff(until_utc, should_be_throttled_until, :millisecond) < 100)
    assert_receive(:some_message, 100)

    assert {:ok,
            %{
              throttled_count: 1,
              status: :throttled,
              extra_data: %{message: :some_message, pid: ^this},
              throttled_until: new_until,
              throttled_until_utc: new_until_utc
            }} = Throttle.send(self(), :some_message, "Throttle.send.1", delay)

    assert(until == new_until)
    assert(until_utc == new_until_utc)
    refute_receive(:some_message, 100)

    assert {:ok, %{throttled_count: 0, status: :executed}} =
             Throttle.send(self(), :some_message, "different_key", delay)

    assert_receive :some_message, 100
  end

  test "Throttle.call calls and then throttles a function correctly" do
    delay = 5_000
    should_be_throttled_until = DateTime.add(DateTime.utc_now(), delay, :millisecond)

    this = self()

    assert {:ok,
            %{
              throttled_count: 0,
              status: :executed,
              extra_data: %{fun: fun},
              throttled_until: until,
              throttled_until_utc: until_utc
            }} = Throttle.call(fn -> send(this, :some_message) end, "Throttle.call.1", delay)

    assert(is_function(fun))
    assert(is_number(until))
    assert(is_struct(until_utc))
    assert(Time.diff(until_utc, should_be_throttled_until, :millisecond) < 100)
    assert_receive(:some_message, 100)

    assert {:ok,
            %{
              throttled_count: 1,
              status: :throttled,
              extra_data: %{fun: new_fun},
              throttled_until: new_until,
              throttled_until_utc: new_until_utc
            }} = Throttle.call(fn -> send(this, :some_message) end, "Throttle.call.1", delay)

    refute_receive(:some_message, 100)

    assert(fun == new_fun)
    assert(until == new_until)
    assert(until_utc == new_until_utc)

    assert {:ok, %{throttled_count: 0, status: :executed}} =
             Throttle.call(fn -> send(this, :some_message) end, "different_key", delay)

    assert_receive(:some_message, 100)
  end

  test "Throttle.apply schedules a function correctly" do
    delay = 5_000
    should_be_throttled_until = DateTime.add(DateTime.utc_now(), delay, :millisecond)

    this = self()

    assert {:ok,
            %{
              throttled_count: 0,
              status: :executed,
              extra_data: %{module: Process, fun: :send, args: [^this, :some_message, []]},
              throttled_until: until,
              throttled_until_utc: until_utc
            }} = Throttle.apply(Process, :send, [self(), :some_message, []], "Throttle.apply.1", delay)

    assert(is_number(until))
    assert(is_struct(until_utc))
    assert(Time.diff(until_utc, should_be_throttled_until, :millisecond) < 100)
    assert_receive(:some_message, 100)

    assert {:ok,
            %{
              throttled_count: 1,
              status: :throttled,
              extra_data: %{module: Process, fun: :send, args: [^this, :some_message, []]},
              throttled_until: new_until,
              throttled_until_utc: new_until_utc
            }} = Throttle.apply(Process, :send, [self(), :some_message, []], "Throttle.apply.1", delay)

    assert(until == new_until)
    assert(until_utc == new_until_utc)

    assert {:ok, %{throttled_count: 0, status: :executed}} =
             Throttle.call(fn -> send(this, :some_message) end, "different_key", delay)

    assert_receive(:some_message, 100)
  end

  test "Throttle.apply executes a function correctly" do
    delay = 100
    Throttle.apply(Process, :send, [self(), :some_message, []], "Debounce.apply.1", delay)
    assert_receive :some_message, 1_000
  end

  test "Throttle.state returns correct state" do
    state = Throttle.state()
    assert(state == Server.initial_state()[:throttled])
    Throttle.apply(Process, :send, [self(), :some_message, []], "Throttle.apply.1", 100)
    state = Throttle.state()
    assert(length(Map.keys(state[:apply])) == 1)
    assert(length(Map.keys(state[:send])) == 0)
    assert(length(Map.keys(state[:call])) == 0)
    key_state = get_in(state, [:apply, "Throttle.apply.1"])
    assert(%Throttle{} = key_state)
  end
end
