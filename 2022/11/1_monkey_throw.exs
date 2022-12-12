#!/usr/bin/env elixir

Mix.install([{:nimble_parsec, "~> 1.2"}])

Code.require_file("./parser.exs", Path.dirname(__ENV__.file))

worry_level = fn
  %{operation: :*, operator: :old}, item -> item * item
  %{operation: :*, operator: operator}, item -> item * operator
  %{operation: :+, operator: :old}, item -> item + item
  %{operation: :+, operator: operator}, item -> item + operator
end

run_round = fn monkeys ->
  for %{nr: nr, operation: operation, test: test} <- monkeys, reduce: monkeys do
    monkeys ->
      for item <- Enum.at(monkeys, nr).items, reduce: monkeys do
        monkeys ->
          item_worry_level = trunc(worry_level.(operation, item) / 3)
          throw_target = if rem(item_worry_level, test.divisor) == 0, do: test.do, else: test.else

          monkeys
          |> update_in(
            [Access.at(nr)],
            &%{&1 | items: tl(&1.items), inspections: &1.inspections + 1}
          )
          |> update_in(
            [Access.at(throw_target)],
            &%{&1 | items: &1.items ++ [item_worry_level]}
          )
      end
  end
end

{:ok, monkeys, "", _, _, _} =
  IO.stream()
  |> Enum.into("")
  |> Parser.parse()

1..20
|> Enum.reduce(monkeys, fn _i, acc -> run_round.(acc) end)
|> Enum.map(& &1.inspections)
|> Enum.sort(:desc)
|> Enum.take(2)
|> Enum.product()
|> IO.puts()
