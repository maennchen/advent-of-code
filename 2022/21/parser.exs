defmodule Parser do
  import NimbleParsec

  newline = ignore(string("\n"))

  monkey_name = ascii_string([?a..?z], min: 1)

  operator =
    choice([
      replace(string("+"), :+),
      replace(string("-"), :-),
      replace(string("/"), :/),
      replace(string("*"), :*)
    ])

  monkey =
    monkey_name
    |> concat(ignore(string(": ")))
    |> concat(
      choice([
        integer(min: 1),
        monkey_name
        |> concat(ignore(string(" ")))
        |> concat(operator)
        |> concat(ignore(string(" ")))
        |> concat(monkey_name)
        |> wrap()
        |> map({List, :to_tuple, []})
      ])
    )
    |> wrap()
    |> map({List, :to_tuple, []})

  defparsec(
    :parse,
    concat(monkey, newline)
    |> times(min: 1)
    |> wrap()
    |> map({Map, :new, []})
  )
end
