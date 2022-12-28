#!/usr/bin/env elixir

Mix.install([{:nimble_parsec, "~> 1.2"}])

Code.require_file("./parser.exs", Path.dirname(__ENV__.file))
Code.require_file("./solver.exs", Path.dirname(__ENV__.file))

defmodule BackTracker do
  def define_answer(monkeys) do
    {monkeys, dependency, expected_result} =
      monkeys
      |> precalculate_results()
      |> case do
        {%{"root" => {<<dependency_a::binary>>, _operation, result_b}} = monkeys, :stop} ->
          {monkeys, dependency_a, result_b}

        {%{"root" => {result_a, _operation, <<dependency_b::binary>>}} = monkeys, :stop} ->
          {monkeys, dependency_b, result_a}
      end

    get_calculation_for(monkeys, dependency, expected_result)
  end

  defp precalculate_results(monkeys) do
    cur_search_value = monkeys["humn"]

    {monkeys, result} = Solver.solve(%{monkeys | "humn" => :stop}, "root")

    {%{monkeys | "humn" => cur_search_value}, result}
  end

  defp get_calculation_for(monkeys, cur, expected_result)
  defp get_calculation_for(_monkeys, "humn", expected_result), do: expected_result

  defp get_calculation_for(monkeys, cur, expected_result) do
    case monkeys[cur] do
      {<<next::binary>>, :+, num} when is_integer(num) ->
        get_calculation_for(monkeys, next, expected_result - num)

      {num, :+, <<next::binary>>} when is_integer(num) ->
        get_calculation_for(monkeys, next, expected_result - num)

      {<<next::binary>>, :-, num} when is_integer(num) ->
        get_calculation_for(monkeys, next, expected_result + num)

      {num, :-, <<next::binary>>} when is_integer(num) ->
        get_calculation_for(monkeys, next, num - expected_result)

      {<<next::binary>>, :*, num} when is_integer(num) ->
        get_calculation_for(monkeys, next, Integer.floor_div(expected_result, num))

      {num, :*, <<next::binary>>} when is_integer(num) ->
        get_calculation_for(monkeys, next, Integer.floor_div(expected_result, num))

      {<<next::binary>>, :/, num} when is_integer(num) ->
        get_calculation_for(monkeys, next, expected_result * num)

      {num, :/, <<next::binary>>} when is_integer(num) ->
        get_calculation_for(monkeys, next, Integer.floor_div(expected_result, num))
    end
  end
end

{:ok, [%{"root" => {root_dependency_a, _operation, root_dependency_b}} = monkeys], "", _, _, _} =
  IO.stream()
  |> Enum.into("")
  |> Parser.parse()

monkeys = %{
  monkeys
  | "root" => {root_dependency_a, :=, root_dependency_b},
    "humn" => BackTracker.define_answer(monkeys)
}

{%{"humn" => humn} = _monkeys, true} = Solver.solve(monkeys, "root")

IO.puts(humn)
