#!/usr/bin/env elixir

Mix.install([{:nimble_parsec, "~> 1.2"}])

Code.require_file("./parser.exs", Path.dirname(__ENV__.file))
Code.require_file("./solver.exs", Path.dirname(__ENV__.file))

{:ok, [monkeys], "", _, _, _} =
  IO.stream()
  |> Enum.into("")
  |> Parser.parse()

{_monkeys, solution} = Solver.solve(monkeys, "root")

IO.puts(solution)
