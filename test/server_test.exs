defmodule ServerTest do
  use ExUnit.Case
  alias DebounceAndThrottle.{Throttle, Server}

  setup do
    Server.reset()
    :ok
  end

  test "Server.reset works properly" do
    assert(:sys.get_state(Server) == Server.initial_state())
    Throttle.call(fn -> send(self(), :some_message) end, "Throttle.call.1", 10_000)
    assert(:sys.get_state(Server) != Server.initial_state())
    Server.reset()
    assert(:sys.get_state(Server) == Server.initial_state())
  end

  test "Server.cleanup works properly" do
    assert(:sys.get_state(Server) == Server.initial_state())
    Throttle.call(fn -> send(self(), :some_message) end, "Throttle.call.1", -10_000)
    assert(:sys.get_state(Server) != Server.initial_state())
    new_state = Server.cleanup(:sys.get_state(Server), [:call, :apply, :send])
    assert(new_state == Server.initial_state())
  end

  test "Test unknown message doesnt crash Genserver" do
    send(Server, :unknown_message)
    :timer.sleep(100)
    assert(is_map(DebounceAndThrottle.Debounce.state()))
  end
end
