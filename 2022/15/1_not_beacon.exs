#!/usr/bin/env elixir

[check_y] = System.argv()

check_y = String.to_integer(check_y)

distance = fn {origin_x, origin_y}, {target_x, target_y} ->
  abs(origin_x - target_x) + abs(origin_y - target_y)
end

reachable = fn origin, target, max_distance ->
  distance.(origin, target) <= max_distance
end

positions =
  IO.stream()
  |> Enum.map(fn line ->
    [sensor_x, sensor_y, beacon_x, beacon_y] =
      ~r/Sensor at x=(?<sensor_x>-?\d+), y=(?<sensor_y>-?\d+): closest beacon is at x=(?<beacon_x>-?\d+), y=(?<beacon_y>-?\d+)/
      |> Regex.run(line, capture: ["sensor_x", "sensor_y", "beacon_x", "beacon_y"])
      |> Enum.map(&String.to_integer/1)

    %{sensor: {sensor_x, sensor_y}, beacon: {beacon_x, beacon_y}}
  end)
  |> Enum.map(&Map.put(&1, :distance, distance.(&1.sensor, &1.beacon)))

max_distance =
  positions
  |> Enum.map(& &1.distance)
  |> Enum.max()

min_x =
  positions
  |> Enum.flat_map(&[&1.sensor, &1.beacon])
  |> Enum.map(&elem(&1, 1))
  |> Enum.min()
  |> Kernel.-(max_distance)

max_x =
  positions
  |> Enum.flat_map(&[&1.sensor, &1.beacon])
  |> Enum.map(&elem(&1, 1))
  |> Enum.max()
  |> Kernel.+(max_distance)

min_x..max_x
|> Enum.filter(fn x ->
  Enum.any?(positions, fn
    %{beacon: {^x, ^check_y}} ->
      false

    %{sensor: sensor, distance: distance} ->
      reachable.(sensor, {x, check_y}, distance)
  end)
end)
|> Enum.count()
|> IO.inspect()
