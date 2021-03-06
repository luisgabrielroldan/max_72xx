# Max72XX

[![CircleCI](https://circleci.com/gh/luisgabrielroldan/max_72xx.svg?style=svg)](https://circleci.com/gh/luisgabrielroldan/max_72xx)
[![Hex version](https://img.shields.io/hexpm/v/max_72xx.svg "Hex version")](https://hex.pm/packages/max_72xx)
[![Hex docs](http://img.shields.io/badge/hex.pm-docs-green.svg "Hex docs")](https://hexdocs.pm/max_72xx)

Max72XX is a library for driving arrays of MAX72XX as a pixel device.

![Demo](images/demo.jpg)

## Setup

Add the library to your mix.exs deps:

```elixir
def deps do
  [
    {:max_72xx, "~> 0.1.0"}
  ]
end
```

Run mix deps.get to download the new dependency.

## Usage

1. Connect the array to the SPI (There are many guides on Internet)

2. Start the driver

```elixir
{:ok, ref} <- Max72XX.Array.start_link("spidev0.0", 4)
```

3. Draw pixels and update the matrix

```elixir
Max72XX.Array.set_pixel(ref, x, y)
...
Max72XX.Array.update(ref)
```

