#!/usr/bin/env elixir

IO.stream()
|> Stream.map(&String.split(String.trim(&1), " ", parts: 2))
|> Stream.map(fn [oponent, me] ->
  {case oponent do
     "A" -> :rock
     "B" -> :paper
     "C" -> :scissors
   end,
   case me do
     "X" -> :rock
     "Y" -> :paper
     "Z" -> :scissors
   end}
end)
|> Stream.map(fn {oponent, me} ->
  won =
    case {oponent, me} do
      {same, same} -> 3
      {:rock, :paper} -> 6
      {:paper, :scissors} -> 6
      {:scissors, :rock} -> 6
      {_, _} -> 0
    end

  score_draw =
    case me do
      :rock -> 1
      :paper -> 2
      :scissors -> 3
    end

  won + score_draw
end)
|> Enum.sum()
|> IO.puts()
