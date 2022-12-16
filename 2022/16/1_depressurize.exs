#!/usr/bin/env elixir

initial_position = "AA"
available_minutes = 30

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

distances =
  for origin <- Map.keys(valves),
      origin == "AA" or valves[origin].flow_rate > 0,
      target <- Map.keys(valves),
      origin != target,
      valves[target].flow_rate > 0 do
    path = :digraph.get_short_path(graph, origin, target)
    {origin, target, length(path) - 1}
  end
  |> Enum.group_by(&elem(&1, 0), &{elem(&1, 1), elem(&1, 2)})
  |> Map.new(&{elem(&1, 0), Map.new(elem(&1, 1))})

:digraph.delete(graph)

defmodule PathFinder do
  defp async_mapper do
    fn input, callback ->
      input
      |> Task.async_stream(callback)
      |> Enum.map(fn {:ok, res} -> res end)
    end
  end

  def find_path(
        origin,
        remaining_minutes,
        distances,
        valves,
        acc_enabled_valves \\ [],
        mapper \\ async_mapper()
      ) do
    distances
    |> Map.fetch!(origin)
    |> Enum.reject(&(elem(&1, 0) in acc_enabled_valves))
    |> mapper.(fn
      {target, distance} when distance + 1 < remaining_minutes ->
        new_remaining_minutes = remaining_minutes - (distance + 1)

        released_pressure = new_remaining_minutes * Map.fetch!(valves, target).flow_rate

        released_pressure +
          find_path(
            target,
            new_remaining_minutes,
            distances,
            valves,
            [target | acc_enabled_valves],
            &Enum.map/2
          )

      {_target, _distance} ->
        0
    end)
    |> Enum.max(fn -> 0 end)
  end
end

initial_position
|> PathFinder.find_path(available_minutes, distances, valves)
|> IO.puts()
