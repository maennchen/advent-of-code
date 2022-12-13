#!/usr/bin/env elixir

defmodule Order do
  def check({left, right}) do
    [
      List.wrap(left),
      right |> List.wrap() |> pad_with_nil()
    ]
    |> Enum.zip()
    |> Enum.reduce_while(true, fn
      pair, acc ->
        with nil <- check_pair(pair) do
          {:cont, acc}
        else
          result -> {:halt, result}
        end
    end)
  end

  defp check_pair({same, same}), do: nil
  defp check_pair({nil, _right}), do: nil
  defp check_pair({_left, nil}), do: false
  defp check_pair({left, right}) when is_integer(left) and is_integer(right), do: left < right
  defp check_pair({left, right} = pair) when is_list(left) or is_list(right), do: check(pair)
  defp check_pair(_pair), do: nil

  defp pad_with_nil(stream), do: Stream.concat(stream, Stream.repeatedly(fn -> nil end))
end

IO.stream()
|> Enum.map(fn packet ->
  {packet, _} = Code.eval_string(packet)

  packet
end)
|> Enum.reject(&is_nil/1)
|> Enum.chunk_every(2)
|> Enum.map(&List.to_tuple/1)
|> Enum.with_index(1)
|> Enum.filter(fn {packet, _index} -> Order.check(packet) end)
|> Enum.map(&elem(&1, 1))
|> Enum.sum()
|> IO.puts()
