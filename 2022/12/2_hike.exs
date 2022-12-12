#!/usr/bin/env elixir

Code.require_file("./graph.exs", Path.dirname(__ENV__.file))

{heights, _start_position, end_position} =
  IO.stream()
  |> Enum.with_index()
  |> Enum.reduce({%{}, nil, nil}, fn {line, row_index}, {acc, start_position, end_position} ->
    line =
      line
      |> String.trim()
      |> String.to_charlist()

    heights =
      line
      |> Enum.with_index()
      |> Enum.map(fn
        {letter, column_index} when letter in ?a..?z -> {{row_index, column_index}, letter - ?a}
        {?S, column_index} -> {{row_index, column_index}, 0}
        {?E, column_index} -> {{row_index, column_index}, 25}
      end)

    start_position =
      case Enum.find_index(line, &(&1 == ?S)) do
        nil -> start_position
        column_index -> {row_index, column_index}
      end

    end_position =
      case Enum.find_index(line, &(&1 == ?E)) do
        nil -> end_position
        column_index -> {row_index, column_index}
      end

    {Map.merge(acc, Map.new(heights)), start_position, end_position}
  end)

possible_start_positions =
  heights
  |> Enum.filter(&match?({_index, 0}, &1))
  |> Enum.map(&elem(&1, 0))

heights
|> Map.keys()
|> Graph.new(
  for {{row_index, column_index} = start_index, start_height} <- heights,
      search_index <- [
        {row_index, column_index - 1},
        {row_index, column_index + 1},
        {row_index - 1, column_index},
        {row_index + 1, column_index}
      ],
      Map.has_key?(heights, search_index),
      search_height = Map.fetch!(heights, search_index),
      search_height <= start_height + 1,
      reduce: %{} do
    acc -> Map.update(acc, search_index, [start_index], &[start_index | &1])
  end
)
|> Graph.dijkstra_all(end_position, possible_start_positions)
|> Enum.reject(&match?(:no_path, &1))
|> Enum.min()
|> IO.puts()
