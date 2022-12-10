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

states =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> stream_flat_scan.(1, &execute_command.(&1, &2))

[1]
|> Stream.concat(states)
|> Enum.with_index(1)
|> Stream.filter(&match?({_value, index} when rem(index, 40) == 20, &1))
|> Stream.map(&(elem(&1, 0) * elem(&1, 1)))
|> Enum.sum()
|> IO.puts()
