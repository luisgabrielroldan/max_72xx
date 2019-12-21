defmodule Max72XX.Array.Impl do
  @moduledoc false

  alias Circuits.SPI
  alias Max72XX.Array.Buffer
  alias Max72XX.Array

  @max7219_reg_decodemode 0x9
  @max7219_reg_intensity 0xA
  @max7219_reg_scanlimit 0xB
  @max7219_reg_shutdown 0xC
  @max7219_reg_displaytest 0xF

  def init(device, size, opts) do
    array = %Array{
      size: size,
      bus_adapter: opts[:adapter] || SPI,
      buffer: Buffer.new(size)
    }

    with {:ok, array} <- bus_open(array, device),
         {:ok, array} <- init_device(array) do
      {:ok, array}
    end
  end

  def load_bitmap(%Array{buffer: buffer} = array, bitmap) when is_binary(bitmap) do
    case Buffer.load_bitmap(buffer, bitmap) do
      {:ok, buffer} ->
        array
        |> Map.put(:buffer, buffer)
        |> reply_ok()

      error ->
        {:reply, error, array}
    end
  end

  def load_buffer(%Array{buffer: buffer} = array, %Buffer{} = src) do
    case Buffer.load_buffer(buffer, src) do
      {:ok, buffer} ->
        array
        |> Map.put(:buffer, buffer)
        |> reply_ok()

      error ->
        {:reply, error, array}
    end
  end

  def set_pixel(%Array{buffer: buffer} = array, x, y, state) do
    buffer = Buffer.set_pixel(buffer, x, y, state)

    array
    |> Map.put(:buffer, buffer)
    |> reply_ok()
  end

  def clear(%Array{buffer: buffer} = array) do
    buffer = Buffer.clear(buffer)

    array
    |> Map.put(:buffer, buffer)
    |> reply_ok()
  end

  def update(%Array{} = array) do
    case buffer_send(array) do
      :ok ->
        {:reply, :ok, array}

      {:error, reason} ->
        {:reply, {:error, reason}, array}
    end
  end

  def set_test_mode(%Array{} = array, enabled?) do
    reg_value =
      cond do
        enabled? -> 1
        true -> 0
      end

    case send_all_reg(array, @max7219_reg_displaytest, reg_value) do
      :ok ->
        {:reply, :ok, array}

      {:error, reason} ->
        {:reply, {:error, reason}, array}
    end
  end

  def set_shutdown(%Array{} = array, on?) do
    reg_value =
      cond do
        on? -> 1
        true -> 0
      end

    case send_all_reg(array, @max7219_reg_shutdown, reg_value) do
      :ok ->
        {:reply, :ok, array}

      {:error, reason} ->
        {:reply, {:error, reason}, array}
    end
  end

  def set_intensity(%Array{} = array, level)
      when level >= 0 and level <= 0xF do
    case send_all_reg(array, @max7219_reg_intensity, level) do
      :ok ->
        {:reply, :ok, %{array | intensity: level}}

      {:error, reason} ->
        {:stop, {:error, reason}, array}
    end
  end

  def set_intensity(%Array{} = array, _level),
    do: {:reply, {:error, :arg}, array}

  def get_dimensions(%Array{buffer: buffer} = array) do
    {w, h} = Buffer.get_dimensions(buffer)

    {:reply, {:ok, w, h}, array}
  end

  def terminate(%Array{bus_adapter: adapter, bus_ref: ref}),
    do: adapter.close(ref)

  defp bus_open(array, device) do
    case array.bus_adapter.open(device) do
      {:ok, ref} ->
        {:ok, %{array | bus_ref: ref}}

      error ->
        error
    end
  end

  defp init_device(array) do
    with :ok <- send_all_reg(array, @max7219_reg_displaytest, 0),
         :ok <- send_all_reg(array, @max7219_reg_scanlimit, 7),
         :ok <- send_all_reg(array, @max7219_reg_decodemode, 0),
         :ok <- send_all_reg(array, @max7219_reg_intensity, 0xA),
         :ok <- buffer_send(array),
         :ok <- send_all_reg(array, @max7219_reg_shutdown, 1) do
      {:ok, array}
    end
  end

  defp buffer_send(%{buffer: buffer} = array) do
    buffer
    |> Buffer.to_commands()
    |> Enum.reduce_while(:ok, fn row_data, _ ->
      case transfer(array, row_data) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp send_all_reg(%{size: size} = array, reg, value) do
    data =
      for _ <- 1..size, into: <<>> do
        <<reg, value>>
      end

    transfer(array, data)
  end

  defp transfer(%{bus_adapter: adapter, bus_ref: ref}, data) do
    case adapter.transfer(ref, data) do
      {:ok, _} ->
        :ok

      error ->
        error
    end
  end

  defp reply_ok(array),
    do: {:reply, :ok, array}
end
