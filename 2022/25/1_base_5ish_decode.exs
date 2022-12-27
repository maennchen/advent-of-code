#!/usr/bin/env elixir

defmodule SNAFU do
  def decode(number), do: number |> String.reverse() |> _decode(0, 0)

  defp _decode(number, exponent, acc)
  defp _decode("", _exponent, acc), do: acc

  defp _decode("-" <> rest, exponent, acc),
    do: _decode(rest, exponent + 1, acc + Integer.pow(5, exponent) * -1)

  defp _decode("=" <> rest, exponent, acc),
    do: _decode(rest, exponent + 1, acc + Integer.pow(5, exponent) * -2)

  defp _decode(<<other::utf8, rest::binary>>, exponent, acc),
    do: _decode(rest, exponent + 1, acc + Integer.pow(5, exponent) * (other - ?0))

  def encode(number, acc \\ "")
  def encode(0, acc), do: acc

  def encode(number, acc) do
    cond do
      rem(number, 5) == 3 -> encode(ceil(number / 5), "=#{acc}")
      rem(number, 5) == 4 -> encode(ceil(number / 5), "-#{acc}")
      true -> encode(trunc(number / 5), "#{rem(number, 5)}#{acc}")
    end
  end
end

IO.stream()
|> Stream.map(&String.trim/1)
|> Stream.map(&SNAFU.decode/1)
|> Enum.sum()
|> SNAFU.encode()
|> IO.puts()
