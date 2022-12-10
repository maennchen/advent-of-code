#!/usr/bin/env elixir

add = fn {x1, y1}, {x2, y2} -> {x1 + x2, y1 + y2} end

follow = fn
  {hx, y}, {tx, y} when abs(hx - tx) == 2 ->
    {trunc((tx + hx) / 2), y}

  {x, hy}, {x, ty} when abs(hy - ty) == 2 ->
    {x, trunc((hy + ty) / 2)}

  {hx, hy}, {tx, ty} when abs(hx - tx) == 2 and abs(hy - ty) == 1 ->
    {trunc((hx + tx) / 2), hy}

  {hx, hy}, {tx, ty} when abs(hx - tx) == 1 and abs(hy - ty) == 2 ->
    {hx, trunc((hy + ty) / 2)}

  {hx, hy}, {tx, ty} when abs(hx - tx) == 2 and abs(hy - ty) == 2 ->
    {trunc((hx + tx) / 2), trunc((hy + ty) / 2)}

  _head_position, tail_position ->
    tail_position
end

direction_to_move = fn
  ?R -> {1, 0}
  ?L -> {-1, 0}
  ?U -> {0, 1}
  ?D -> {0, -1}
end

{_positions, tail_route} =
  IO.stream()
  |> Stream.map(&String.trim/1)
  |> Stream.flat_map(fn <<direction::size(8), " ", number::binary>> ->
    List.duplicate(direction_to_move.(direction), String.to_integer(number))
  end)
  |> Enum.reduce(
    {List.duplicate({0, 0}, 10), MapSet.new([{0, 0}])},
    fn head_movement, {[head_position | tail_positions], tail_route} ->
      new_head_position = add.(head_position, head_movement)

      new_positions = [
        new_head_position | Enum.scan(tail_positions, new_head_position, &follow.(&2, &1))
      ]

      {new_positions, MapSet.put(tail_route, List.last(new_positions))}
    end
  )

IO.puts(Enum.count(tail_route))
