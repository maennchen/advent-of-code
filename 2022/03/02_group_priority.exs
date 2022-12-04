#!/usr/bin/env elixir

IO.stream()
|> Stream.map(&String.trim/1)
|> Stream.map(&MapSet.new(String.to_charlist(&1)))
|> Stream.chunk_every(3)
|> Stream.flat_map(fn group ->
  Enum.reduce(group, &MapSet.intersection/2)
end)
|> Stream.map(fn
  char when char in ?a..?z -> char - ?a + 1
  char when char in ?A..?Z -> char - ?A + 1 + 26
end)
|> Enum.sum()
|> IO.puts()
