defmodule Max72XX.Array do
  @moduledoc """
  Controls a linear array of MAX72XX LED Drivers.
  """

  use GenServer

  alias Max72XX.Array.Buffer
  alias Max72XX.Array.Impl

  @type array_ref :: pid()
  @type pixel_state :: Buffer.pixel_state()

  @type option :: GenServer.option() | {:adapter, module()}
  @type start_options :: [option]

  @type t :: %__MODULE__{
          size: integer(),
          bus_ref: term(),
          bus_adapter: module(),
          buffer: Buffer.t(),
          intensity: integer()
        }

  defstruct size: nil,
            bus_ref: nil,
            bus_adapter: nil,
            buffer: nil,
            intensity: nil

  @doc """
  Starts an array driver process.

  Arguments:
  `device`: The device where the array is connected (ie: "spidev0.0").
  `size`: The number of matrices in the array.
  """
  @spec start_link(device :: String.t(), size :: integer(), start_options()) ::
          {:ok, array_ref()} | {:error, term()}
  def start_link(device, size, opts \\ [])
      when is_binary(device) and is_integer(size),
      do: GenServer.start_link(__MODULE__, [device, size, opts], opts)

  @doc """
  Stop driver
  """
  def stop(pid),
    do: GenServer.stop(pid)

  @doc """
  Set the intensitiy of the LED's
  Valid values for level are 0-15
  """
  @spec set_intensity(server :: array_ref, level :: integer()) :: :ok | {:error, term()}
  def set_intensity(pid, level),
    do: GenServer.call(pid, {:set_intensity, level})

  @doc """
  Load bitmap
  """
  @spec load_bitmap(server :: array_ref, bitmap :: binary()) :: :ok | {:error, term()}
  def load_bitmap(pid, bitmap),
    do: GenServer.call(pid, {:load_bitmap, bitmap})

  @doc """
  Load buffer
  """
  @spec load_buffer(server :: array_ref, buffer :: Buffer.t()) :: :ok | {:error, term()}
  def load_buffer(pid, buffer),
    do: GenServer.call(pid, {:load_buffer, buffer})

  @doc """
  Get dimensions
  """
  @spec get_dimensions(server :: array_ref) :: {:ok, integer(), integer()}
  def get_dimensions(pid),
    do: GenServer.call(pid, :get_dimensions)

  @doc """
  Enable test mode
  """
  @spec set_test_mode(server :: array_ref, enabled :: boolean()) :: :ok | {:error, term()}
  def set_test_mode(pid, enabled),
    do: GenServer.call(pid, {:set_test_mode, enabled})

  @doc """
  Shutdown mode
  """
  @spec set_shutdown(server :: array_ref, on? :: boolean()) :: :ok | {:error, term()}
  def set_shutdown(pid, on?),
    do: GenServer.call(pid, {:set_shutdown, on?})

  @doc """
  Set pixel.
  """
  @spec set_pixel(ref :: array_ref(), x :: integer(), y :: integer(), state :: pixel_state()) ::
          :ok | {:error, term()}
  def set_pixel(pid, x, y, state \\ true),
    do: GenServer.call(pid, {:set_pixel, x, y, state})

  @doc """
  Clear pixels
  """
  @spec clear(ref :: array_ref()) :: :ok | {:error, term()}
  def clear(pid),
    do: GenServer.call(pid, :clear)

  @doc """
  Updates the array 
  """
  @spec update(ref :: array_ref()) :: :ok | {:error, term()}
  def update(pid),
    do: GenServer.call(pid, :update)

  @impl true
  def init([device, size, opts]) do
    case Impl.init(device, size, opts) do
      {:ok, array} ->
        {:ok, array}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_call({:load_bitmap, bitmap}, _from, array),
    do: Impl.load_bitmap(array, bitmap)

  def handle_call({:load_buffer, buffer}, _from, array),
    do: Impl.load_buffer(array, buffer)

  def handle_call({:set_intensity, level}, _from, array),
    do: Impl.set_intensity(array, level)

  def handle_call({:set_pixel, x, y, state}, _from, array),
    do: Impl.set_pixel(array, x, y, state)

  def handle_call({:set_test_mode, enabled}, _from, array),
    do: Impl.set_test_mode(array, enabled)

  def handle_call({:set_shutdown, on?}, _from, array),
    do: Impl.set_shutdown(array, on?)

  def handle_call(:get_dimensions, _from, array),
    do: Impl.get_dimensions(array)

  def handle_call(:clear, _from, array),
    do: Impl.clear(array)

  def handle_call(:update, _from, array),
    do: Impl.update(array)

  @impl true
  def terminate(_reason, array),
    do: Impl.terminate(array)
end
