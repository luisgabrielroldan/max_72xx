defmodule Max72XX.DummySPI do
  def open(_bus_name, _opts \\ []),
    do: {:ok, :good}

  def transfer(_spi_bus, data),
    do: {:ok, data}

  def close(_spi_bus),
    do: :ok
end
