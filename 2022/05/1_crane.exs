#!/usr/bin/env elixir

move_regex = ~r/^move (?<count>\d+) from (?<from>\d+) to (?<to>\d+)$/

read_stack_line = fn line, stacks ->
  line
  |> String.codepoints()
  |> Enum.chunk_every(4)
  |> Enum.map(&Enum.at(&1, 1))
  |> Enum.map(fn
    " " -> nil
    crate -> crate
  end)
  |> Enum.with_index()
  |> Enum.reduce(stacks, fn
    {nil, _stack_index}, stacks ->
      stacks

    {crate, stack_index}, stacks ->
      update_in(stacks, [Access.at!(stack_index)], &(&1 ++ [crate]))
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
|> Enum.reduce([[], [], [], [], [], [], [], [], []], fn
  line, stacks ->
    cond do
      match?("[" <> _rest, String.trim(line)) ->
        read_stack_line.(line, stacks)

      match?(" 1 " <> _rest, line) ->
        stacks

      match?("", line) ->
        stacks

      match?("move" <> _rest, line) ->
        %{"count" => count, "from" => from, "to" => to} =
          move_regex
          |> Regex.named_captures(line)
          |> Map.new(&{elem(&1, 0), String.to_integer(elem(&1, 1))})

        Enum.reduce(1..count, stacks, move_crate.(from, to))
    end
end)
|> Enum.map(&List.first/1)
|> Enum.reject(&is_nil/1)
|> Enum.join()
|> IO.puts()
