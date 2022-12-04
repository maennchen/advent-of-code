#!/usr/bin/env elixir

line_regex = ~r/^(?<a_from>\d+)-(?<a_to>\d+),(?<b_from>\d+)-(?<b_to>\d+)/

IO.stream()
|> Stream.map(&Regex.named_captures(line_regex, &1))
|> Stream.filter(fn %{"a_from" => a_from, "a_to" => a_to, "b_from" => b_from, "b_to" => b_to} ->
  a = MapSet.new(String.to_integer(a_from)..String.to_integer(a_to))
  b = MapSet.new(String.to_integer(b_from)..String.to_integer(b_to))

  not MapSet.disjoint?(a, b)
end)
|> Enum.count()
|> IO.puts()
