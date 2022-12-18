#!/usr/bin/env elixir

path_to_access = fn [x, y, z] ->
  [Access.key(x, %{}), Access.key(y, %{}), Access.key(z, false)]
end

lava_cubes =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> Stream.map(fn line -> line |> String.split(",") |> Enum.map(&String.to_integer/1) end)
  |> Enum.reduce(%{}, fn path, acc ->
    put_in(acc, path_to_access.(path), true)
  end)

checks = [{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}]

total =
  for {x, row} <- lava_cubes,
      {y, column} <- row,
      {z, true} <- column,
      {x_delta, y_delta, z_delta} <- checks,
      get_in(lava_cubes, path_to_access.([x + x_delta, y + y_delta, z + z_delta])) == false,
      reduce: 0 do
    acc -> acc + 1
  end

IO.puts(total)
