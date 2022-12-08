#!/usr/bin/env elixir

grid =
  [row | _rest] =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.codepoints/1)
  |> Stream.map(fn row ->
    Enum.map(row, &String.to_integer/1)
  end)
  |> Enum.to_list()

height = length(grid)
width = length(row)

get_surrounding_trees = fn row_index, column_index ->
  row = Enum.at(grid, row_index)
  column = Enum.map(grid, &Enum.at(&1, column_index))

  [
    Enum.slice(column, 0, row_index),
    Enum.slice(column, row_index + 1, height),
    Enum.slice(row, 0, column_index),
    Enum.slice(row, column_index + 1, width)
  ]
end

visible_from_outside = fn row_index, column_index, tree ->
  row_index
  |> get_surrounding_trees.(column_index)
  |> Enum.any?(fn around -> Enum.all?(around, &(&1 < tree)) end)
end

count =
  for {row, row_index} <- Enum.with_index(grid),
      {tree, column_index} <- Enum.with_index(row),
      visible_from_outside.(row_index, column_index, tree),
      reduce: 0 do
    acc -> acc + 1
  end

IO.puts(count)
