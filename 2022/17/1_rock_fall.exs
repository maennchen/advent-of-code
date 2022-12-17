#!/usr/bin/env elixir

Mix.install([{:stream_split, "~> 0.1.7"}])

chamber_width = 7

rock_drop_count = 2022

rock_formations = [
  [
    [true, true, true, true]
  ],
  [
    [false, true, false],
    [true, true, true],
    [false, true, false]
  ],
  [
    [false, false, true],
    [false, false, true],
    [true, true, true]
  ],
  [
    [true],
    [true],
    [true],
    [true]
  ],
  [
    [true, true],
    [true, true]
  ]
]

push_directions =
  IO.stream(1024)
  |> Stream.map(&String.trim_trailing/1)
  |> Stream.flat_map(&String.codepoints/1)
  |> Stream.map(fn
    "<" -> -1
    ">" -> 1
  end)
  |> Enum.to_list()

rock_generator = Stream.cycle(rock_formations)

push_direction_generator = Stream.cycle(push_directions)

defmodule Dropper do
  def drop(rock_shape, {field, top_rock, push_direction_generator}) do
    drop(
      rock_shape,
      field,
      push_direction_generator,
      top_rock,
      2,
      top_rock - 3 - length(rock_shape)
    )
  end

  defp drop(rock_shape, field, push_direction_generator, top_rock, x, y) do
    {push, push_direction_generator} = StreamSplit.pop(push_direction_generator)

    x =
      try do
        x = x + push

        place_rock_in_field(rock_shape, field, x, y)

        x
      catch
        {:collision, _with} -> x
      end

    try do
      y = y + 1

      place_rock_in_field(rock_shape, field, x, y)

      drop(rock_shape, field, push_direction_generator, top_rock, x, y)
    catch
      {:collision, _with} ->
        field = place_rock_in_field(rock_shape, field, x, y)

        {field, min(top_rock, y), push_direction_generator}
    end
  end

  defp place_rock_in_field(_rock_shape, _field, x, _y) when x < 0, do: throw({:collision, :wall})

  defp place_rock_in_field([first_rock_shape_row | _rest] = rock_shape, field, x, y) do
    if length(first_rock_shape_row) + x > unquote(chamber_width) do
      throw({:collision, :wall})
    end

    if length(rock_shape) - 1 + y >= 0 do
      throw({:collision, :floor})
    end

    rock_shape
    |> Enum.with_index()
    |> Map.new(fn {row, index} ->
      {index + y, row |> Enum.with_index() |> Map.new(&{elem(&1, 1) + x, elem(&1, 0)})}
    end)
    |> Map.merge(field, fn _key, a, b ->
      Map.merge(a, b, fn
        _key, true, true ->
          throw({:collision, :rock})

        _key, a, b ->
          a || b
      end)
    end)
  end
end

{_field, top_rock, _push_direction_egenrator} =
  rock_generator
  |> Stream.take(rock_drop_count)
  |> Enum.reduce(
    {%{}, 0, push_direction_generator},
    &Dropper.drop/2
  )

IO.puts(abs(top_rock))
