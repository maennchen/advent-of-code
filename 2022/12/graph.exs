defmodule Graph do
  defstruct edges: %{}, vertices: MapSet.new()

  def new(vertices, edges), do: %__MODULE__{edges: edges, vertices: vertices}

  def dijkstra(graph, start_vertex, end_vertex) do
    graph
    |> dijkstra_all(start_vertex, [end_vertex])
    |> List.first()
  end

  def dijkstra_all(
        %__MODULE__{vertices: vertices, edges: edges} = _graph,
        start_vertex,
        end_vertices
      ) do
    unvisited_vertices = MapSet.new(vertices)

    vertices_distance =
      vertices
      |> Map.new(&{&1, :infinity})
      |> Map.put(start_vertex, 0)

    vertices_distance =
      edges
      |> visit(start_vertex, unvisited_vertices, vertices_distance, fn unvisited_vertices ->
        Enum.any?(end_vertices, &MapSet.member?(unvisited_vertices, &1))
      end)

    end_vertices
    |> Enum.map(&Map.fetch!(vertices_distance, &1))
    |> Enum.map(fn
      :infinity -> :no_path
      distance -> distance
    end)
  end

  defp visit(edges, current_vertex, unvisited_vertices, vertices_distance, continue_callback) do
    current_distance = Map.fetch!(vertices_distance, current_vertex)
    unvisited_vertices = MapSet.delete(unvisited_vertices, current_vertex)

    vertices_distance =
      edges
      |> Map.get(current_vertex, [])
      |> Enum.filter(&MapSet.member?(unvisited_vertices, &1))
      |> Enum.reduce(vertices_distance, fn target_vertex, vertices_distance ->
        new_distance = current_distance + 1

        Map.update!(vertices_distance, target_vertex, fn
          :infinity -> new_distance
          distance when distance > new_distance -> new_distance
          distance -> distance
        end)
      end)

    if continue_callback.(unvisited_vertices) do
      vertices_distance
      |> Enum.reject(&match?({_index, :infinity}, &1))
      |> Enum.sort_by(&elem(&1, 1))
      |> Enum.map(&elem(&1, 0))
      |> Enum.filter(&MapSet.member?(unvisited_vertices, &1))
      |> case do
        [] ->
          vertices_distance

        [next_vertex | _others] ->
          visit(edges, next_vertex, unvisited_vertices, vertices_distance, continue_callback)
      end
    else
      vertices_distance
    end
  end
end
