defmodule Parser do
  import NimbleParsec

  newline = ignore(string("\n"))

  # Monkey 0:
  monkey_nr =
    ignore(string("Monkey "))
    |> concat(unwrap_and_tag(integer(min: 1), :nr))
    |> concat(ignore(string(":")))

  #   Starting items: 79, 98
  starting_items =
    ignore(string("  Starting items: "))
    |> concat(
      integer(min: 1)
      |> concat(ignore(string(", ")))
      |> repeat()
    )
    |> concat(integer(min: 1))
    |> wrap()
    |> unwrap_and_tag(:items)

  #   Operation: new = old * 19
  operation =
    ignore(string("  Operation: new = old "))
    |> concat(
      unwrap_and_tag(choice([replace(string("+"), :+), replace(string("*"), :*)]), :operation)
    )
    |> concat(ignore(string(" ")))
    |> concat(unwrap_and_tag(choice([integer(min: 1), replace(string("old"), :old)]), :operator))
    |> wrap()
    |> map({Map, :new, []})
    |> unwrap_and_tag(:operation)

  #     If true: throw to monkey 2
  truthy =
    ignore(string("    If true: throw to monkey "))
    |> concat(integer(min: 1))
    |> unwrap_and_tag(:do)

  #     If false: throw to monkey 2
  falsy =
    ignore(string("    If false: throw to monkey "))
    |> concat(integer(min: 1))
    |> unwrap_and_tag(:else)

  #   Test: divisible by 23
  test =
    ignore(string("  Test: divisible by "))
    |> concat(unwrap_and_tag(integer(min: 1), :divisor))
    |> concat(newline)
    |> concat(truthy)
    |> concat(newline)
    |> concat(falsy)
    |> wrap()
    |> map({Map, :new, []})
    |> unwrap_and_tag(:test)

  monkey =
    monkey_nr
    |> concat(newline)
    |> concat(starting_items)
    |> concat(newline)
    |> concat(operation)
    |> concat(newline)
    |> concat(test)
    |> concat(newline)
    |> wrap()
    |> map({Map, :new, []})
    |> map({Map, :put, [:inspections, 0]})

  defparsec(
    :parse,
    concat(monkey, newline)
    |> times(min: 1)
  )
end
