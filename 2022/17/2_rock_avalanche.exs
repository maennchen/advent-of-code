#!/usr/bin/env elixir

Mix.install([{:stream_split, "~> 0.1.7"}])

import Bitwise

require Logger

clean_interval = 1000

rock_formations = [
  {[0b1111], 4},
  {[0b010, 0b111, 0b010], 3},
  {[0b100, 0b100, 0b111], 3},
  {[0b1, 0b1, 0b1, 0b1], 1},
  {[0b11, 0b11], 2}
]

push_directions =
  IO.stream(1024)
  |> Stream.map(&String.trim_trailing/1)
  |> Stream.flat_map(&String.codepoints/1)
  |> Enum.map(fn
    "<" -> -1
    ">" -> 1
  end)

left_push_direction =
  push_directions
  |> Stream.with_index()
  |> Stream.filter(&match?({-1, _index}, &1))
  |> Stream.map(&elem(&1, 1))
  |> MapSet.new()

push_direction_count = length(push_directions)

rock_drop_count = 1_000_000_000_000
repetition_sample_size = 500
repetition_comparison_size = 50

if rem(repetition_sample_size, length(rock_formations)) != 0,
  do: raise("use multiple of rock formation size as sample size")

rock_generator = Stream.cycle(rock_formations)

push_direction_generator = Stream.cycle(push_directions)

defmodule Dropper do
  def drop({rock_shape, rock_shape_width}, {field, top_rock, push_direction_generator}) do
    start_y = top_rock - 3 - length(rock_shape)
    start_x = 2

    {initial_pushes, push_direction_generator} =
      StreamSplit.take_and_drop(push_direction_generator, 3)

    initial_x_offset =
      Enum.reduce(initial_pushes, start_x, fn push, acc ->
        max(min(acc + push, 7 - rock_shape_width), 0)
      end)

    drop(
      rock_shape,
      field,
      push_direction_generator,
      top_rock,
      initial_x_offset,
      start_y + 3
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

  defp place_rock_in_field(rock_shape, field, x, y) do
    if length(rock_shape) - 1 + y >= 0 do
      throw({:collision, :floor})
    end

    rock_shape
    |> Enum.map(&(&1 <<< x))
    |> Kernel.tap(fn shape ->
      for line <- shape, line > 0b1111111, do: throw({:collision, :wall})
    end)
    |> Enum.with_index(y)
    |> Map.new(&{elem(&1, 1), elem(&1, 0)})
    |> Map.merge(field, fn _key, a, b ->
      if (a &&& b) > 0 do
        throw({:collision, :rock})
      end

      a ||| b
    end)
  end

  def print(field, label) do
    {min_y, max_y} = field |> Map.keys() |> Enum.min_max()

    IO.puts("=============== " <> label)

    for y <- min_y..max_y, into: IO.stream() do
      row = Map.get(field, y, 0)

      [
        y |> abs() |> inspect() |> String.pad_leading(4),
        ": ",
        row
        |> Integer.to_string(2)
        |> String.pad_leading(7, "0")
        |> String.reverse()
        |> String.replace("0", ".")
        |> String.replace("1", "#"),
        "\n"
      ]
    end

    field
  end

  def clean_bottom_rows(field) do
    {min_y, max_y} = field |> Map.keys() |> Enum.min_max()

    min_y..max_y
    |> Enum.reduce_while({:search, 0}, fn y, {:search, acc} ->
      acc = acc ||| Map.get(field, y, 0)

      if acc >= 0b1111111 do
        {:halt, {:found, y}}
      else
        {:cont, {:search, acc}}
      end
    end)
    |> case do
      {:search, _acc} ->
        field

      {:found, complete_y} ->
        Map.drop(
          field,
          Enum.to_list(
            max(complete_y + 1, min_y + unquote(repetition_comparison_size) + 2)..max_y
          )
        )
    end
  end
end

Logger.info("Calculating Sample Set")

{sample_field, sample_top_rock, push_direction_generator} =
  rock_generator
  |> Stream.take(repetition_sample_size)
  |> Enum.reduce({%{}, 0, push_direction_generator}, &Dropper.drop/2)

sample_field = Dropper.clean_bottom_rows(sample_field)

sample_search =
  for y <- sample_top_rock..(sample_top_rock + repetition_comparison_size),
      do: Map.get(sample_field, y, 0)

Dropper.print(sample_field, "")

Logger.info("Searching for inclusion of sample set")

{:duplicate, total_field, repetition_rock_count, total_top_rock} =
  rock_generator
  |> Stream.take(rock_drop_count - repetition_sample_size)
  |> Stream.with_index(1)
  |> Enum.reduce_while({sample_field, sample_top_rock, push_direction_generator}, fn
    {rock, index}, state ->
      {field, top_rock, push_direction_generator} = Dropper.drop(rock, state)

      field = Dropper.clean_bottom_rows(field)

      if rem(index, 100_000) == 0 do
        IO.inspect(index)
      end

      comparison =
        for y <- top_rock..(top_rock + repetition_comparison_size), do: Map.get(field, y, 0)

      if comparison == sample_search do
        {:halt, {:duplicate, field, index, top_rock}}
      else
        {:cont, {field, top_rock, push_direction_generator}}
      end
  end)

repetition_top_rock = total_top_rock - sample_top_rock

Logger.info("Found repetition after #{repetition_rock_count} rocks")

total_field = Dropper.clean_bottom_rows(total_field)

Dropper.print(total_field, "")

rock_drop_count = rock_drop_count - repetition_sample_size

repetion_needed_count = trunc(rock_drop_count / repetition_rock_count)

rock_drop_count = rem(rock_drop_count, repetition_rock_count)

Logger.info("Calculate remaining rocks after repetition")

{after_repetition_field, after_repetition_top_rock, _push_direction_generator} =
  rock_generator
  |> Stream.take(rock_drop_count)
  |> Enum.reduce({sample_field, sample_top_rock, push_direction_generator}, &Dropper.drop/2)

after_repetition_field = Dropper.clean_bottom_rows(after_repetition_field)

Dropper.print(after_repetition_field, "")

additional_height_after_repetition = abs(after_repetition_top_rock - sample_top_rock)

Logger.info(
  "Total Rocks: #{abs(sample_top_rock) + abs(repetion_needed_count * repetition_top_rock) + additional_height_after_repetition}"
)
