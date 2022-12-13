#!/usr/bin/env elixir

defmodule PackageComparator do
  def compare([], []), do: :eq
  def compare([_ | _], []), do: :gt
  def compare([], [_ | _]), do: :lt

  def compare([x | x_rest], [y | y_rest]) when is_integer(x) and is_integer(y) do
    cond do
      x < y -> :lt
      x > y -> :gt
      x == y -> compare(x_rest, y_rest)
    end
  end

  def compare([x | x_rest], [y | y_rest]) when is_list(x) and is_list(y) do
    case compare(x, y) do
      :eq -> compare(x_rest, y_rest)
      :lt -> :lt
      :gt -> :gt
    end
  end

  def compare([x | x_rest], [y | y_rest]),
    do: compare([List.wrap(x) | x_rest], [List.wrap(y) | y_rest])
end

IO.stream()
|> Enum.map(fn packet ->
  {packet, _} = Code.eval_string(packet)

  packet
end)
|> Enum.reject(&is_nil/1)
|> Enum.concat([[[2]], [[6]]])
|> Enum.sort(PackageComparator)
|> Enum.with_index(1)
|> Enum.filter(&match?({pair, _index} when pair in [[[2]], [[6]]], &1))
|> Enum.map(&elem(&1, 1))
|> Enum.product()
|> IO.puts()
