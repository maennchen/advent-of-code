#!/usr/bin/env elixir

start_x = 500

animation_time = 0

show_every = 1000

{display_width, 0} = System.cmd("/usr/bin/tput", ["cols"])
display_width = display_width |> String.trim() |> String.to_integer()

{display_height, 0} = System.cmd("/usr/bin/tput", ["lines"])
display_height = display_height |> String.trim() |> String.to_integer()

field = %{
  0 => %{start_x => :start}
}

rock_formations =
  IO.stream()
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn rock_formation ->
    [head | rest] =
      ~r/(?<x>\d+),(?<y>\d+)/
      |> Regex.scan(rock_formation, capture: :all_names)
      |> Enum.map(fn corner ->
        corner |> Enum.map(&String.to_integer/1) |> List.to_tuple()
      end)

    rest
    |> Enum.scan([head], fn
      {start_x, y}, [{stop_x, y} | _rest] ->
        Enum.map(start_x..stop_x, &{&1, y})

      {x, start_y}, [{x, stop_y} | _rest] ->
        Enum.map(start_y..stop_y, &{x, &1})
    end)
    |> List.flatten()
  end)

field =
  for rock_formation <- rock_formations, {x, y} <- rock_formation, reduce: field do
    field -> Map.update(field, y, %{x => :rock}, &Map.put(&1, x, :rock))
  end

rock_max_y =
  rock_formations
  |> List.flatten()
  |> Enum.map(&elem(&1, 1))
  |> Enum.max()

print = fn field, result ->
  min_y = 0
  max_y = min(rock_max_y + 2, display_height)

  distance_from_middle = trunc((display_width - 1) / 2)
  min_x = start_x - distance_from_middle
  max_x = start_x + distance_from_middle
  left_padding = trunc((display_width - 1) / 2 - distance_from_middle)

  for y <- min_y..max_y, into: IO.stream() do
    if y == rock_max_y + 2 do
      [
        String.duplicate(" ", left_padding),
        IO.ANSI.light_white_background(),
        IO.ANSI.light_white(),
        String.duplicate("#", trunc(distance_from_middle - String.length(result) / 2)),
        " ",
        IO.ANSI.black(),
        result,
        IO.ANSI.light_white(),
        " ",
        String.duplicate("#", trunc(distance_from_middle - String.length(result) / 2)),
        IO.ANSI.black_background(),
        IO.ANSI.white()
      ]
    else
      [
        String.duplicate(" ", left_padding),
        for x <- min_x..max_x do
          case field[y][x] do
            :start -> [IO.ANSI.green_background(), IO.ANSI.green(), "+"]
            :rock -> [IO.ANSI.light_white_background(), IO.ANSI.light_white(), "#"]
            :trail -> [IO.ANSI.light_black_background(), IO.ANSI.light_black(), "~"]
            :sand -> [IO.ANSI.yellow_background(), IO.ANSI.yellow(), "o"]
            nil -> [IO.ANSI.black_background(), IO.ANSI.black(), "."]
          end
        end,
        IO.ANSI.black_background(),
        IO.ANSI.white(),
        "\n"
      ]
    end
  end

  if result == "",
    do: Enum.into([IO.ANSI.cursor_up(max_y), IO.ANSI.cursor_left(display_width)], IO.stream())
end

drop_sand = fn field, max_y ->
  [nil]
  |> Stream.cycle()
  |> Enum.reduce_while({field, {start_x, 0}}, fn
    _, {field, {_current_x, current_y}} when current_y > max_y ->
      {:halt, {:ok, field}}

    _, {field, {current_x, current_y}} ->
      action =
        cond do
          field[current_y + 1][current_x] in [nil, :trail] ->
            {:fall, {current_x, current_y + 1}}

          field[current_y + 1][current_x - 1] in [nil, :trail] ->
            {:fall, {current_x - 1, current_y + 1}}

          field[current_y + 1][current_x + 1] in [nil, :trail] ->
            {:fall, {current_x + 1, current_y + 1}}

          true ->
            :blocked
        end

      case action do
        :blocked ->
          if current_x == 500 and current_y == 0 do
            {:halt, {:blocked, field}}
          else
            {:halt, {:ok, field}}
          end

        {:fall, {new_x, new_y} = new_position} ->
          field =
            field
            |> update_in([current_y, current_x], fn
              :start -> :start
              :sand -> :trail
            end)
            |> put_in([Access.key(new_y, %{}), Access.key(new_x, nil)], :sand)

          {:cont, {field, new_position}}
      end
  end)
end

print.(field, "")

{field, count} =
  animation_time
  |> Stream.interval()
  |> Stream.with_index(1)
  |> Enum.reduce_while(field, fn {_, i}, field ->
    if rem(i, show_every) == 0, do: print.(field, "")

    field
    |> drop_sand.(rock_max_y + 0)
    |> case do
      {:ok, field} -> {:cont, field}
      {:blocked, _field} -> {:halt, {field, i}}
    end
  end)

print.(field, inspect(count))
