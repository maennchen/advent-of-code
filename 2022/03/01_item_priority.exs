#!/usr/bin/env elixir

IO.stream()
|> Stream.map(&String.trim/1)
|> Stream.map(&String.to_charlist/1)
|> Stream.map(&Enum.split(&1, trunc(length(&1) / 2)))
|> Stream.flat_map(fn {a, b} ->
  MapSet.intersection(MapSet.new(a), MapSet.new(b))
end)
|> Stream.map(fn
  char when char in ?a..?z -> char - ?a + 1
  char when char in ?A..?Z -> char - ?A + 1 + 26
end)
|> Enum.sum()
|> IO.puts()
