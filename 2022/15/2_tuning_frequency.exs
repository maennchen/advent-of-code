#!/usr/bin/env elixir

[max_x_y] = System.argv()
max_x_y = String.to_integer(max_x_y)

distance = fn {origin_x, origin_y}, {target_x, target_y} ->
  abs(origin_x - target_x) + abs(origin_y - target_y)
end

range_on_line = fn line, {origin_x, origin_y}, max_distance ->
  line_distance = abs(origin_y - line)

  if line_distance <= max_distance do
    (origin_x - (max_distance - line_distance))..(origin_x + (max_distance - line_distance))
  end
end

merge_ranges = fn ranges ->
  ranges
  |> Enum.sort_by(& &1.first)
  |> Enum.reduce([], fn
    range, [] ->
      [range]

    range, [last_range | rest] ->
      if Range.disjoint?(range, last_range) do
        [range, last_range | rest]
      else
        [min(range.first, last_range.first)..max(range.last, last_range.last) | rest]
      end
  end)
  |> Enum.reverse()
end

holes_in_ranges = fn ranges, total_range ->
  case ranges do
    [] ->
      [total_range]

    [_ | _] ->
      List.flatten([
        if(Range.disjoint?(total_range, List.first(ranges)),
          do: total_range.first..(List.first(ranges).first - 1)//1,
          else: []
        ),
        ranges
        |> Enum.chunk_every(2, 1)
        |> Enum.flat_map(fn
          [_..a, b.._] -> (a + 1)..(b - 1)//1
          [_] -> []
        end),
        if(Range.disjoint?(total_range, List.last(ranges)),
          do: (List.last(ranges).last + 1)..total_range.last//1,
          else: []
        )
      ])
  end
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

[{x, y}] =
  0..max_x_y
  |> Task.async_stream(
    fn y ->
      [
        positions
        |> Enum.filter(&match?(%{beacon: {_x, ^y}}, &1))
        |> Enum.map(fn %{beacon: {x, ^y}} -> x..x end),
        positions
        |> Enum.flat_map(fn %{sensor: sensor, distance: max_distance} ->
          case range_on_line.(y, sensor, max_distance) do
            nil -> []
            range -> [range]
          end
        end)
      ]
      |> List.flatten()
      |> merge_ranges.()
      |> holes_in_ranges.(0..max_x_y)
      |> Enum.map(&{&1, y})
    end,
    ordered: false
  )
  |> Stream.flat_map(fn {:ok, holes} -> holes end)
  |> Enum.take(1)

IO.puts(x * 4_000_000 + y)
