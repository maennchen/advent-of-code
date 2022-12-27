#!/usr/bin/env elixir

key = 811_589_153

numbers =
  IO.stream()
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.map(&(&1 * key))

number_length = length(numbers)

indexes = 0..(number_length - 1)

move_index = fn old_index, delta ->
  Integer.mod(old_index + delta, number_length - 1)
end

{_indexes, numbers} =
  numbers
  |> Enum.with_index()
  |> Stream.duplicate(10)
  |> Stream.flat_map(& &1)
  |> Enum.reduce({indexes, numbers}, fn {number, index}, {indexes, numbers} ->
    old_pos = Enum.find_index(indexes, &match?(^index, &1))
    new_pos = move_index.(old_pos, number)

    {Enum.slide(indexes, old_pos, new_pos), Enum.slide(numbers, old_pos, new_pos)}
  end)

zero_index = Enum.find_index(numbers, &match?(0, &1))

[1_000, 2_000, 3_000]
|> Enum.map(&rem(zero_index + &1, number_length))
|> Enum.map(&Enum.at(numbers, &1))
|> Enum.sum()
|> IO.puts()
