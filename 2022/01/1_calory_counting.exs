#!/usr/bin/env elixir

{max, _curr} =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> Enum.reduce({0, 0}, fn
    "", {max, curr} when curr > max -> {curr, 0}
    "", {max, _curr} -> {max, 0}
    number, {max, curr} -> {max, curr + String.to_integer(number)}
  end)

IO.puts(max)
