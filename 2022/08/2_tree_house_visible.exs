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
    Enum.map((row_index - 1)..0//-1, &Enum.at(column, &1)),
    Enum.slice(column, row_index + 1, height),
    Enum.map((column_index - 1)..0//-1, &Enum.at(row, &1)),
    Enum.slice(row, column_index + 1, width)
  ]
end

visible_score_from_tree_house = fn row_index, column_index, tree ->
  row_index
  |> get_surrounding_trees.(column_index)
  |> Enum.map(fn direction ->
    max(
      case Enum.find_index(direction, &(&1 >= tree)) do
        nil -> length(direction)
        index -> index + 1
      end,
      1
    )
  end)
  |> Enum.reduce(&(&1 * &2))
end

count =
  for {row, row_index} <- Enum.with_index(grid),
      {tree, column_index} <- Enum.with_index(row),
      score = visible_score_from_tree_house.(row_index, column_index, tree),
      reduce: 0 do
    acc when acc < score -> score
    acc -> acc
  end

IO.puts(count)
