defmodule LiveEnumTest do
  use ExUnit.Case
  doctest LiveEnum

  test "greets the world" do
    assert LiveEnum.hello() == :world
  end
end
