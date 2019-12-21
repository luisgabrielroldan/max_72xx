defmodule Max72XXTest.ArrayTest do
  use ExUnit.Case

  alias Max72XX.DummySPI
  alias Max72XX.Array
  alias Max72XX.Array.Buffer

  @array_size 4

  defp get_bitmap(size \\ @array_size),
    do: Enum.map(1..(8 * size), &<<&1>>) |> Enum.into(<<>>)

  test "start/stop driver" do
    assert {:ok, ref} = Array.start_link("spi", @array_size, adapter: DummySPI)
    assert :ok == Array.stop(ref)
  end

  describe "test api" do
    setup do
      {:ok, ref} = Array.start_link("spi", @array_size, adapter: DummySPI)
      {:ok, %{ref: ref}}
    end

    test "set_intensity/2", %{ref: ref} do
      assert {:error, :arg} == Array.set_intensity(ref, -1)
      assert :ok == Array.set_intensity(ref, 8)
      assert {:error, :arg} == Array.set_intensity(ref, 16)
    end

    test "load_bitmap/2", %{ref: ref} do
      assert :ok == Array.load_bitmap(ref, get_bitmap())
      assert {:error, :size} == Array.load_bitmap(ref, get_bitmap(2))
    end

    test "load_buffer/2", %{ref: ref} do
      assert :ok == Array.load_buffer(ref, Buffer.new(@array_size))
      assert {:error, :size} == Array.load_buffer(ref, Buffer.new(2))
    end

    test "get_dimensions/1", %{ref: ref} do
      assert {:ok, 32, 8} == Array.get_dimensions(ref)
    end

    test "set_test_mode/2", %{ref: ref} do
      assert :ok == Array.set_test_mode(ref, true)
      assert :ok == Array.set_test_mode(ref, false)
    end

    test "set_shutdown/2", %{ref: ref} do
      assert :ok == Array.set_shutdown(ref, true)
      assert :ok == Array.set_shutdown(ref, false)
    end

    test "set_pixel/3", %{ref: ref} do
      assert :ok == Array.set_pixel(ref, 0, 0)
    end

    test "clear/1", %{ref: ref} do
      assert :ok == Array.clear(ref)
    end

    test "update/1", %{ref: ref} do
      assert :ok == Array.update(ref)
    end
  end
end
