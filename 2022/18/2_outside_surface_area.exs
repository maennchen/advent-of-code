#!/usr/bin/env elixir

require Logger

path_to_access = fn [x, y, z] ->
  [Access.key(x, %{}), Access.key(y, %{}), Access.key(z, :water)]
end

Logger.info("Building Matrix of obsidian")

lava_cubes =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> Stream.map(fn line -> line |> String.split(",") |> Enum.map(&String.to_integer/1) end)
  |> Enum.reduce(%{}, fn path, acc ->
    put_in(acc, path_to_access.(path), :obsidian)
  end)

{min_x, max_x} = lava_cubes |> Map.keys() |> Enum.min_max()
{min_y, max_y} = lava_cubes |> Map.values() |> Enum.flat_map(&Map.keys/1) |> Enum.min_max()

{min_z, max_z} =
  lava_cubes
  |> Map.values()
  |> Enum.flat_map(&Map.values/1)
  |> Enum.flat_map(&Map.keys/1)
  |> Enum.min_max()

Logger.info(
  "Dimensions: #{inspect(%{min_x: min_x, max_x: max_x, min_y: min_y, max_y: max_y, min_z: min_z, max_z: max_z}, pretty: true)}"
)

Logger.info("Building Water Graph")

reachable_from_outside_graph = :digraph.new()

for x <- (min_x - 1)..(max_x + 1),
    y <- (min_y - 1)..(max_y + 1),
    z <- (min_z - 1)..(max_z + 1),
    get_in(lava_cubes, path_to_access.([x, y, z])) == :water,
    do: :digraph.add_vertex(reachable_from_outside_graph, {x, y, z})

checks = [{-1, 0, 0}, {1, 0, 0}, {0, -1, 0}, {0, 1, 0}, {0, 0, -1}, {0, 0, 1}]

Logger.info("Connecting Water Cells")

for x <- (min_x - 1)..(max_x + 1),
    y <- (min_y - 1)..(max_y + 1),
    z <- (min_z - 1)..(max_z + 1),
    get_in(lava_cubes, path_to_access.([x, y, z])) == :water,
    {x_delta, y_delta, z_delta} <- checks,
    get_in(lava_cubes, path_to_access.([x + x_delta, y + y_delta, z + z_delta])) == :water,
    do:
      :digraph.add_edge(
        reachable_from_outside_graph,
        {x, y, z},
        {x + x_delta, y + y_delta, z + z_delta}
      )

Logger.info("Detecting Bubbles")

closed_lava_masses =
  for x <- min_x..max_x,
      y <- min_y..max_y,
      z <- min_z..max_z,
      get_in(lava_cubes, path_to_access.([x, y, z])) == :water,
      :digraph.get_short_path(
        reachable_from_outside_graph,
        {min_x - 1, min_y - 1, min_z - 1},
        {x, y, z}
      ) == false,
      reduce: lava_cubes do
    acc ->
      put_in(acc, path_to_access.([x, y, z]), :buble)
  end

Logger.info("Finding Outside area")

total =
  for {x, row} <- closed_lava_masses,
      {y, column} <- row,
      {z, :obsidian} <- column,
      {x_delta, y_delta, z_delta} <- checks,
      get_in(closed_lava_masses, path_to_access.([x + x_delta, y + y_delta, z + z_delta])) ==
        :water,
      reduce: 0 do
    acc -> acc + 1
  end

IO.puts(total)
