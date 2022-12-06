#!/usr/bin/env elixir

IO.stream(1024)
|> Stream.flat_map(&String.codepoints/1)
|> Stream.chunk_every(14, 1)
|> Enum.find_index(&(Enum.uniq(&1) == &1))
|> Kernel.then(&IO.puts(&1 + 14))
