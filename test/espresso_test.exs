defmodule EspressoTest do
  use ExUnit.Case
  doctest Espresso

  test "greets the world" do
    assert Espresso.hello() == :world
  end
end
