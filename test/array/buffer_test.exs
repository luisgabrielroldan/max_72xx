defmodule Max72XXTest.Array.BufferTest do
  use ExUnit.Case

  alias Max72XX.Array.Buffer

  test "new/1" do
    assert %Buffer{
             array_size: 2,
             data: %{
               0 => <<0, 0, 0, 0, 0, 0, 0, 0>>,
               1 => <<0, 0, 0, 0, 0, 0, 0, 0>>
             }
           } = Buffer.new(2)
  end

  test "set_pixel/1" do
    buffer = Buffer.new(2)

    buffer =
      buffer
      |> Buffer.set_pixel(0, 0)
      |> Buffer.set_pixel(1, 1)
      |> Buffer.set_pixel(2, 2)
      |> Buffer.set_pixel(3, 3)
      |> Buffer.set_pixel(8, 0)
      |> Buffer.set_pixel(9, 1)
      |> Buffer.set_pixel(10, 2)
      |> Buffer.set_pixel(11, 3)

    assert %Buffer{
             array_size: 2,
             data: %{
               0 => <<0, 64, 32, 16, 0, 0, 0, 0>>,
               1 => <<0, 64, 32, 16, 0, 0, 0, 0>>
             }
           } = buffer
  end

  test "load_bitmap/1" do
    buffer = Buffer.new(2)
    bitmap = <<1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2>>

    assert {:ok,
            %Buffer{
              array_size: 2,
              data: %{
                0 => <<1, 1, 1, 1, 1, 1, 1, 1>>,
                1 => <<2, 2, 2, 2, 2, 2, 2, 2>>
              }
            }} = Buffer.load_bitmap(buffer, bitmap)
  end

  test "to_commands/1" do
    buffer = Buffer.new(2)

    assert [
             <<1, 0, 1, 0>>,
             <<2, 0, 2, 0>>,
             <<3, 0, 3, 0>>,
             <<4, 0, 4, 0>>,
             <<5, 0, 5, 0>>,
             <<6, 0, 6, 0>>,
             <<7, 0, 7, 0>>,
             <<8, 0, 8, 0>>
           ] = Buffer.to_commands(buffer)
  end

  test "get_dimensions/1" do
    buffer = Buffer.new(2)

    assert {16, 8} = Buffer.get_dimensions(buffer)
  end
end
