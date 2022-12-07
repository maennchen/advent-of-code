#!/usr/bin/env elixir

defmodule AdventOfCode202206 do
  defp path_to_access(path, default),
    do:
      path
      |> Enum.reverse()
      |> Enum.map(&Access.key(&1, default))

  defp sum_directory({name, %{} = contents}) do
    contents = Map.new(contents, &sum_directory(&1))

    dir_size =
      contents
      |> Map.values()
      |> Enum.map(fn
        {size, _contents} -> size
        size -> size
      end)
      |> Enum.sum()

    {name, {dir_size, contents}}
  end

  defp sum_directory({name, size}), do: {name, size}

  defp flatten({name, {size, %{} = contents}}, acc_path) do
    [
      {:dir, [name | acc_path], size}
      | Enum.flat_map(contents, &flatten(&1, [name | acc_path]))
    ]
  end

  defp flatten({name, size}, acc_path), do: [{:file, [name | acc_path], size}]

  defp cmd("$ cd /", {acc_dirs, _acc_path}), do: {acc_dirs, []}
  defp cmd("$ cd ..", {acc_dirs, [_current_dir | acc_path]}), do: {acc_dirs, acc_path}
  defp cmd("$ cd " <> dir, {acc_dirs, acc_path}), do: {acc_dirs, [dir | acc_path]}
  defp cmd("$ ls", acc), do: acc

  defp cmd("dir " <> dir, {acc_dirs, acc_path}),
    do: {update_in(acc_dirs, path_to_access([dir | acc_path], %{}), & &1), acc_path}

  defp cmd(file, {acc_dirs, acc_path}) do
    [size, file] = String.split(file, " ", parts: 2)

    dirs =
      update_in(acc_dirs, path_to_access([file | acc_path], %{}), fn _cur ->
        String.to_integer(size)
      end)

    {dirs, acc_path}
  end

  def main(stream) do
    {directories, _path} =
      stream
      |> Stream.map(&String.trim/1)
      |> Enum.reduce({%{}, []}, &cmd/2)

    directories
    |> Map.new(&sum_directory(&1))
    |> Enum.flat_map(&flatten(&1, []))
    |> Enum.filter(&match?({:dir, _path, size} when size < 100_000, &1))
    |> Enum.map(&elem(&1, 2))
    |> Enum.sum()
  end
end

IO.stream()
|> AdventOfCode202206.main()
|> IO.puts()
