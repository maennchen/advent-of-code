#!/usr/bin/env elixir

{calories, _curr} =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> Enum.reduce({[], 0}, fn
    "", {acc, curr} -> {[curr | acc], 0}
    number, {acc, curr} -> {acc, curr + String.to_integer(number)}
  end)

calories
|> Enum.sort(:desc)
|> Enum.slice(0..2)
|> Enum.sum()
|> IO.puts()
