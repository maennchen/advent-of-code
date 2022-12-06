#!/usr/bin/env elixir

read_stack_line = fn line, layers ->
  layer =
    line
    |> String.codepoints()
    |> Enum.chunk_every(4)
    |> Enum.map(&Enum.at(&1, 1))
    |> Enum.map(fn
      " " -> nil
      crate -> crate
    end)

  [layer | layers]
end

finalize_stack = fn layers ->
  layers
  |> Enum.reverse()
  |> Enum.zip_with(fn stack ->
    Enum.reject(stack, &is_nil/1)
  end)
end

move_crate = fn from, to ->
  fn _index, stacks ->
    {crate, stacks} =
      get_and_update_in(stacks, [Access.at!(from - 1), Access.at!(0)], fn _crate -> :pop end)

    update_in(stacks, [Access.at!(to - 1)], &[crate | &1])
  end
end

IO.stream()
|> Stream.map(&String.trim_trailing(&1, "\n"))
|> Enum.reduce([], fn
  line, stacks ->
    cond do
      match?("[" <> _rest, String.trim(line)) ->
        read_stack_line.(line, stacks)

      match?(" 1 " <> _rest, line) ->
        finalize_stack.(stacks)

      match?("", line) ->
        stacks

      match?("move" <> _rest, line) ->
        [count, from, to] =
          ~r/\d+/ |> Regex.scan(line) |> List.flatten() |> Enum.map(&String.to_integer/1)

        Enum.reduce(1..count, stacks, move_crate.(from, to))
    end
end)
|> Enum.map(&List.first/1)
|> Enum.reject(&is_nil/1)
|> Enum.join()
|> IO.puts()
