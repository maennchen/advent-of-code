#!/usr/bin/env elixir

stream_flat_scan = fn stream, acc, fun ->
  Stream.transform(stream, acc, fn entry, acc ->
    elements = fun.(entry, acc)
    result = List.last(elements)
    {elements, result}
  end)
end

execute_command = fn
  "noop", acc -> [acc]
  "addx " <> add, acc -> [acc, acc + String.to_integer(add)]
end

print_crt_line = fn states ->
  states
  |> Enum.with_index()
  |> Enum.map(fn
    {state, index} when abs(state - index) < 2 -> "#"
    _ -> "."
  end)
  |> Enum.join()
  |> IO.puts()
end

states =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> stream_flat_scan.(1, &execute_command.(&1, &2))

[1]
|> Stream.concat(states)
|> Stream.chunk_every(40)
|> Stream.take(6)
|> Enum.each(&print_crt_line.(&1))
