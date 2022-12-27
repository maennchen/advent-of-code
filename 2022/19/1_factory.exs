#!/usr/bin/env elixir

defmodule AsyncEnum do
  def map(list, callback) do
    list
    |> Task.async_stream(callback, timeout: :infinity, ordered: false)
    |> Stream.map(fn {:ok, res} -> res end)
  end
end

defmodule Parser do
  def blueprints(input) do
    input
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn blueprint_line ->
      %{"nr" => blueprint_nr} = Regex.named_captures(~r/Blueprint (?<nr>\d+):/, blueprint_line)

      %{
        nr: String.to_integer(blueprint_nr),
        costs:
          ~r/Each (?<subject>\w+) robot costs ([^\.]+)\./
          |> Regex.scan(blueprint_line)
          |> Map.new(fn [_line, robot_type, costs] ->
            {String.to_existing_atom(robot_type),
             ~r/(?<amount>\d+) (?<resource>\w+)/
             |> Regex.scan(costs)
             |> Map.new(fn [_cost, amount, resource] ->
               {String.to_existing_atom(resource), String.to_integer(amount)}
             end)}
          end)
      }
    end)
  end
end

defmodule Simulator do
  @resources [:ore, :clay, :obsidian, :geode]

  @starting_robots %{
    ore: 1,
    clay: 0,
    obsidian: 0,
    geode: 0
  }

  @starting_state %{
    ore: 0,
    clay: 0,
    obsidian: 0,
    geode: 0
  }

  @total_number_of_minutes 24

  def simulate(costs) do
    max_robots_needed =
      Map.new(@resources, fn
        :geode ->
          {:geode, @total_number_of_minutes}

        resource ->
          {resource,
           costs
           |> Enum.flat_map(&elem(&1, 1))
           |> Keyword.get_values(resource)
           |> Enum.max()}
      end)

    simulate(
      costs,
      @starting_state,
      @starting_robots,
      @total_number_of_minutes,
      &AsyncEnum.map/2,
      max_robots_needed
    )
  end

  def simulate(costs, state, robots, remaining_minutes, mapper, max_robots_needed) do
    @resources
    |> Stream.filter(fn
      :geode -> remaining_minutes > 1
      _resource -> remaining_minutes > 2
    end)
    |> Stream.reject(fn resource ->
      Map.fetch!(robots, resource) + 1 > max_robots_needed[resource]
    end)
    |> mapper.(fn resource ->
      case calculate_waiting_time_for(costs[resource], state, robots) do
        waiting_period when waiting_period == :never or waiting_period >= remaining_minutes - 1 ->
          collect(state, robots, remaining_minutes)

        waiting_period ->
          simulate(
            costs,
            state
            |> collect(robots, waiting_period + 1)
            |> spend(costs[resource]),
            Map.update!(robots, resource, &(&1 + 1)),
            remaining_minutes - (waiting_period + 1),
            &Stream.map/2,
            max_robots_needed
          )
      end
    end)
    |> Enum.max_by(& &1.geode, fn ->
      collect(state, robots, remaining_minutes)
    end)
  end

  defp collect(state, robots, minutes) do
    Enum.reduce(robots, state, fn {resource, amount}, state ->
      Map.update!(state, resource, &(&1 + amount * minutes))
    end)
  end

  defp calculate_waiting_time_for(costs_per_type, state, robots) do
    costs_per_type
    |> Enum.map(fn {resource, cost} ->
      case robots[resource] do
        0 ->
          :never

        num_robots ->
          ceil(max(cost - state[resource], 0) / num_robots)
      end
    end)
    |> Enum.max()
  end

  defp spend(state, costs_per_type) do
    Enum.reduce(
      costs_per_type,
      state,
      &Map.update!(&2, elem(&1, 0), fn num -> num - elem(&1, 1) end)
    )
  end
end

IO.stream()
|> Parser.blueprints()
|> AsyncEnum.map(&(&1.nr * Simulator.simulate(&1.costs).geode))
|> Enum.sum()
|> IO.puts()
