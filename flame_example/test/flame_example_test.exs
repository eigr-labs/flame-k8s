defmodule FlameExampleTest do
  use ExUnit.Case
  doctest FlameExample

  test "greets the world" do
    assert FlameExample.hello() == :world
  end
end
