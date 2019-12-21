defmodule Max72XX.Array.Buffer do
  @moduledoc """
  Represents an array buffer.

  This module is used to store/manipulate the bitmap data in an array.

  As the array module allows to load buffers it can be useful to implement a backbuffer.
  """

  @empty_matrix_bitmap <<0, 0, 0, 0, 0, 0, 0, 0>>
  @matrix_side 8

  defstruct data: nil, array_size: nil

  @type t :: %__MODULE__{}
  @type pixel_state :: boolean()

  @doc """
  Create new buffer
  """
  @spec new(integer()) :: __MODULE__.t()
  def new(array_size) when is_integer(array_size) do
    %__MODULE__{array_size: array_size}
    |> clear()
  end

  @doc """
  Clear buffer (All pixels off)
  """
  @spec clear(buffer :: t()) :: t()
  def clear(%__MODULE__{array_size: array_size} = buffer) do
    data =
      Map.new(0..(array_size - 1), fn index ->
        {index, @empty_matrix_bitmap}
      end)

    %{buffer | data: data}
  end

  @doc """
  Set a pixel on or off
  """
  @spec set_pixel(buffer :: t(), x :: integer(), y :: integer(), state :: pixel_state) :: t()
  def set_pixel(buffer, x, y, state \\ true)

  def set_pixel(%__MODULE__{array_size: size, data: data} = buffer, x, y, state)
      when x > 0 and x < size * @matrix_side and y > 0 and y < @matrix_side do
    matrix_idx = trunc(x / @matrix_side)
    offset = x - matrix_idx * @matrix_side + y * @matrix_side
    matrix_buffer = Map.fetch!(data, matrix_idx)

    <<prev::bitstring-size(offset), _::1, next::bitstring()>> = matrix_buffer

    matrix_buffer =
      case state do
        true ->
          <<prev::bitstring(), 1::1, next::bitstring>>

        _ ->
          <<prev::bitstring(), 0::1, next::bitstring>>
      end

    data = Map.put(data, matrix_idx, matrix_buffer)

    %{buffer | data: data}
  end

  def set_pixel(%__MODULE__{} = buffer, _x, _y, _state),
    do: buffer

  @doc """
  Load the bitmap data from other buffer.
  Both buffers needs to have same dimensions.
  """
  @spec load_buffer(buffer :: t(), source :: t()) :: {:ok, t()} | {:error, :size}
  def load_buffer(%__MODULE__{array_size: size} = buffer, %__MODULE__{array_size: size} = src),
    do: {:ok, %{buffer | data: src.data}}

  def load_buffer(%__MODULE__{}, %__MODULE__{}),
    do: {:error, :size}

  @doc """
  Load bitmap data
  The bitmap needs to fit the array bitmap dimensions (`array_size * 16` bytes)
  """
  @spec load_bitmap(buffer :: t(), bitmap :: binary()) :: {:ok, t()} | {:error, :size}
  def load_bitmap(%__MODULE__{array_size: size}, data)
      when byte_size(data) != size * @matrix_side,
      do: {:error, :size}

  def load_bitmap(%__MODULE__{array_size: size} = buffer, bitmap)
      when is_binary(bitmap) do
    data =
      for(<<row::binary-size(1) <- bitmap>>, do: row)
      |> Enum.chunk_every(size)
      |> Enum.zip()
      |> Enum.map(fn matrix_data ->
        matrix_data
        |> Tuple.to_list()
        |> Enum.into(<<>>)
      end)
      |> Enum.with_index()
      |> Map.new(fn {r, i} -> {i, r} end)

    {:ok, %{buffer | data: data}}
  end

  @doc """
  Returns the buffer dimensions
  """
  @spec get_dimensions(buffer :: t()) :: {width :: integer(), height :: integer()}
  def get_dimensions(%__MODULE__{array_size: size}),
    do: {size * @matrix_side, @matrix_side}

  @doc """
  Returns the list of commands to be send to load the buffer in the device.
  This method is used internally by Array to transfer the data.
  """
  def to_commands(%__MODULE__{data: data}) do
    data
    |> Enum.map(fn {_, mbuf} ->
      for(<<m_row::binary-size(1) <- mbuf>>, do: reverse_byte(m_row))
    end)
    |> Enum.zip()
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {matrix_rows, index} ->
      matrix_rows
      |> Tuple.to_list()
      |> Enum.reverse()
      |> Enum.map(fn row ->
        <<index + 1, row::bitstring>>
      end)
      |> Enum.into(<<>>)
    end)
  end

  defp reverse_byte(<<a::1, b::1, c::1, d::1, e::1, f::1, g::1, h::1>>) do
    <<h::1, g::1, f::1, e::1, d::1, c::1, b::1, a::1>>
  end
end
