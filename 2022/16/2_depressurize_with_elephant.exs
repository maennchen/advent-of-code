#!/usr/bin/env elixir

initial_position = "AA"
available_minutes = 26

valves =
  IO.stream()
  |> Enum.map(
    &Regex.run(
      ~r/^Valve (?<valve>[A-Z]{2}) has flow rate=(?<flow_rate>\d+); tunnels? leads? to valves? (?<tunnels>([A-Z]{2})(, [A-Z]{2})*)/,
      &1,
      capture: ["valve", "flow_rate", "tunnels"]
    )
  )
  |> Map.new(fn [valve, flow_rate, tunnels] ->
    {valve,
     %{
       valve: valve,
       flow_rate: String.to_integer(flow_rate),
       tunnels: String.split(tunnels, ", ")
     }}
  end)

graph = :digraph.new()

for valve <- Map.keys(valves) do
  :digraph.add_vertex(graph, valve)
end

for {valve, %{tunnels: tunnels}} <- valves,
    target_valve <- tunnels do
  :digraph.add_edge(graph, valve, target_valve)
end

non_zero_flow_rate_valves =
  valves
  |> Enum.filter(&match?({_valve, %{flow_rate: flow_rate}} when flow_rate > 0, &1))
  |> Enum.map(&elem(&1, 0))

distances =
  for origin <- ["AA" | non_zero_flow_rate_valves],
      target <- non_zero_flow_rate_valves,
      origin != target do
    path = :digraph.get_short_path(graph, origin, target)
    {origin, target, length(path) - 1}
  end
  |> Map.new(&{{elem(&1, 0), elem(&1, 1)}, elem(&1, 2)})

:digraph.delete(graph)

defmodule PathFinder do
  defp async_mapper do
    fn input, callback ->
      input
      |> Task.async_stream(callback, timeout: :infinity, ordered: false)
      |> Enum.map(fn {:ok, res} -> res end)
    end
  end

  def find_path(
        states,
        distances,
        valves,
        available_valves \\ [],
        mapper \\ async_mapper()
      ) do
    [{origin, remaining_minutes} | rest_states] = Enum.sort_by(states, &elem(&1, 1), :desc)

    available_valves
    |> Enum.map(&{&1, distances[{origin, &1}]})
    |> mapper.(fn
      {target, distance} when distance + 1 < remaining_minutes ->
        remaining_minutes = remaining_minutes - (distance + 1)

        released_pressure = remaining_minutes * Map.fetch!(valves, target).flow_rate

        released_pressure +
          find_path(
            [{target, remaining_minutes} | rest_states],
            distances,
            valves,
            available_valves -- [target],
            &Enum.map/2
          )

      {_target, _distance} when rest_states != [] ->
        find_path(
          rest_states,
          distances,
          valves,
          available_valves,
          &Enum.map/2
        )

      {_target, _distance} ->
        0
    end)
    |> Enum.max(fn -> 0 end)
  end
end

[{"AA", available_minutes}, {"AA", available_minutes}]
|> PathFinder.find_path(distances, valves, non_zero_flow_rate_valves)
|> IO.puts()
