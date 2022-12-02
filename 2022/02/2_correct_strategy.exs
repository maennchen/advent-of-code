#!/usr/bin/env elixir

winning_moves = %{
  rock: :paper,
  paper: :scissors,
  scissors: :rock
}

loosing_moves = Map.new(winning_moves, &{elem(&1, 1), elem(&1, 0)})

outcome_loose = 0
outcome_draw = 3
outcome_win = 6

IO.stream()
|> Stream.map(&String.split(String.trim(&1), " ", parts: 2))
|> Stream.map(fn [oponent, outcome] ->
  {case oponent do
     "A" -> :rock
     "B" -> :paper
     "C" -> :scissors
   end,
   case outcome do
     "X" -> outcome_loose
     "Y" -> outcome_draw
     "Z" -> outcome_win
   end}
end)
|> Stream.map(fn {oponent, outcome} ->
  me =
    case {oponent, outcome} do
      {oponent_move, ^outcome_draw} -> oponent_move
      {oponent_move, ^outcome_win} -> winning_moves[oponent_move]
      {oponent_move, ^outcome_loose} -> loosing_moves[oponent_move]
    end

  score_draw =
    case me do
      :rock -> 1
      :paper -> 2
      :scissors -> 3
    end

  outcome + score_draw
end)
|> Enum.sum()
|> IO.puts()
