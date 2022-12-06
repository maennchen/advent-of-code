#!/usr/bin/env elixir

{_sequence, index} =
  IO.stream(1024)
  |> Stream.flat_map(&String.codepoints/1)
  |> Stream.chunk_every(4, 1)
  |> Stream.with_index()
  |> Enum.find(fn {sequence, _index} ->
    sequence |> Enum.uniq() |> Enum.count() == 4
  end)

IO.puts(index + 4)
