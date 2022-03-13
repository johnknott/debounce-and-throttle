defmodule DebounceTest do
  use ExUnit.Case
  alias DebounceAndThrottle.{Debounce, Server}

  doctest Debounce

  setup do
    Server.reset()
    :ok
  end

  test "Debounce.send schedules an event correctly" do
    delay = 5_000
    should_be_scheduled_at = DateTime.add(DateTime.utc_now(), delay, :millisecond)

    assert {:ok,
            %{
              debounced_count: 1,
              extra_data: %{message: :some_message, pid: Server},
              scheduled_at: time,
              timer_ref: timer_ref
            }} = Debounce.send(Server, :some_message, "Debounce.send.1", delay)

    assert(is_reference(timer_ref))
    assert(is_struct(time))
    assert(Time.diff(time, should_be_scheduled_at, :millisecond) < 100)

    assert {:ok,
            %{
              debounced_count: 2,
              extra_data: %{message: :some_message, pid: Server},
              scheduled_at: new_time,
              timer_ref: new_timer_ref
            }} = Debounce.send(Server, :some_message, "Debounce.send.1", delay)

    assert(timer_ref != new_timer_ref)
    assert(time != new_time)
    refute_receive(:some_message, 100)

    assert {:ok, %{debounced_count: 1}} = Debounce.send(Server, :some_message, "different_key", delay)
  end

  test "Debounce.send executes the command correctly" do
    delay = 100
    Debounce.send(self(), :some_message, "Debounce.send.1", delay)
    assert_receive :some_message, 1_000
  end

  test "Debounce.call schedules an event correctly" do
    delay = 5_000
    should_be_scheduled_at = DateTime.add(DateTime.utc_now(), delay, :millisecond)

    assert {:ok,
            %{
              debounced_count: 1,
              extra_data: %{fun: fun},
              scheduled_at: time,
              timer_ref: timer_ref
            }} = Debounce.call(fn -> IO.puts("Hey1") end, "Debounce.call.1", delay)

    assert(is_reference(timer_ref))
    assert(is_struct(time))
    assert(Time.diff(time, should_be_scheduled_at, :millisecond) < 100)
    assert(is_function(fun))

    assert {:ok,
            %{
              debounced_count: 2,
              scheduled_at: new_time,
              timer_ref: new_timer_ref
            }} = Debounce.call(fn -> IO.puts("Hey1") end, "Debounce.call.1", delay)

    assert(timer_ref != new_timer_ref)
    assert(time != new_time)
    refute_receive(:some_message, 100)

    assert {:ok, %{debounced_count: 1}} = Debounce.call(fn -> IO.puts("Hey2") end, "Debounce.call.2", delay)
  end

  test "Debounce.call executes the function correctly" do
    delay = 100
    this = self()

    Debounce.call(fn -> send(this, :some_message) end, "Debounce.call.3", delay)

    assert_receive :some_message, 1_000
  end

  test "Debounce.apply schedules a function correctly" do
    delay = 5_000
    should_be_scheduled_at = DateTime.add(DateTime.utc_now(), delay, :millisecond)

    this = self()

    assert {:ok,
            %{
              debounced_count: 1,
              extra_data: %{module: Process, fun: :send, args: [^this, :some_message, []]},
              scheduled_at: time,
              timer_ref: timer_ref
            }} = Debounce.apply(Process, :send, [self(), :some_message, []], "Debounce.apply.1", delay)

    assert(is_reference(timer_ref))
    assert(is_struct(time))
    assert(Time.diff(time, should_be_scheduled_at, :millisecond) < 100)

    assert {:ok,
            %{
              debounced_count: 2,
              scheduled_at: new_time,
              timer_ref: new_timer_ref
            }} = Debounce.apply(Process, :send, [self(), :some_message, []], "Debounce.apply.1", delay)

    assert(timer_ref != new_timer_ref)
    assert(time != new_time)
    refute_receive(:some_message, 100)

    assert {:ok, %{debounced_count: 1}} = Debounce.call(fn -> IO.puts("Hey2") end, "Debounce.apply.2", delay)
  end

  test "Debounce.apply executes a function correctly" do
    delay = 100

    Debounce.apply(Process, :send, [self(), :some_message, []], "Debounce.apply.1", delay)
    assert_receive :some_message, 1_000
  end

  test "Debounce.state returns correct state" do
    state = Debounce.state()
    assert(state == Server.initial_state()[:debounced])
    Debounce.apply(Process, :send, [self(), :some_message, []], "Debounce.apply.1", 100)
    state = Debounce.state()
    assert(length(Map.keys(state[:apply])) == 1)
    assert(length(Map.keys(state[:send])) == 0)
    assert(length(Map.keys(state[:call])) == 0)
    key_state = get_in(state, [:apply, "Debounce.apply.1"])
    assert(%Debounce{} = key_state)
  end
end
