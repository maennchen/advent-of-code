#!/usr/bin/env elixir

Mix.install([{:nimble_parsec, "~> 1.2"}])

# Actually not needed, all dividers were prime in the input.
defmodule Prime do
  def prime_factors(n) do
    case Enum.find(2..(n - 1), &(rem(n, &1) == 0)) do
      nil -> [n]
      prime -> [prime, prime_factors(div(n, prime))]
    end
  end
end

Code.require_file("./parser.exs", Path.dirname(__ENV__.file))

worry_level = fn
  %{operation: :*, operator: :old}, item -> item * item
  %{operation: :*, operator: operator}, item -> item * operator
  %{operation: :+, operator: :old}, item -> item + item
  %{operation: :+, operator: operator}, item -> item + operator
end

{:ok, monkeys, "", _, _, _} =
  IO.stream()
  |> Enum.into("")
  |> Parser.parse()

lowest_common_multiplier =
  monkeys
  |> Enum.map(& &1.test.divisor)
  |> Enum.flat_map(&Prime.prime_factors/1)
  |> Enum.uniq()
  |> Enum.product()

run_round = fn monkeys ->
  for %{nr: nr, operation: operation, test: test} <- monkeys, reduce: monkeys do
    monkeys ->
      for item <- Enum.at(monkeys, nr).items, reduce: monkeys do
        monkeys ->
          item_worry_level = rem(worry_level.(operation, item), lowest_common_multiplier)
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

1..10_000
|> Enum.reduce(monkeys, fn _i, acc -> run_round.(acc) end)
|> Enum.map(& &1.inspections)
|> Enum.sort(:desc)
|> Enum.take(2)
|> Enum.product()
|> IO.puts()
