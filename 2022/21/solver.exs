defmodule Solver do
  @operations %{
    +: &Kernel.+/2,
    -: &Kernel.-/2,
    /: &Integer.floor_div/2,
    *: &Kernel.*/2,
    =: &Kernel.==/2
  }

  def solve(monkeys, cur) do
    case monkeys[cur] do
      {monkey_dependency_a, operation, monkey_dependency_b} ->
        {monkeys, dependency_result_a} = solve(monkeys, monkey_dependency_a)
        {monkeys, dependency_result_b} = solve(monkeys, monkey_dependency_b)

        cond do
          dependency_result_a == :stop and dependency_result_b == :stop ->
            {monkeys, :stop}

          dependency_result_a == :stop ->
            {%{monkeys | cur => {monkey_dependency_a, operation, dependency_result_b}}, :stop}

          dependency_result_b == :stop ->
            {%{monkeys | cur => {dependency_result_a, operation, monkey_dependency_b}}, :stop}

          true ->
            solution = @operations[operation].(dependency_result_a, dependency_result_b)

            {%{monkeys | cur => solution}, solution}
        end

      num when is_integer(num) ->
        {monkeys, num}

      :stop ->
        {monkeys, :stop}
    end
  end
end
