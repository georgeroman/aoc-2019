{width, height} = {25, 6}

layers =
  Regex.scan(~r/./, File.read!("day8.input") |> String.trim())
  |> List.flatten()
  |> Enum.chunk_every(width * height)

case System.argv() do
  ["1"] ->
    layers
    |> Enum.map(fn l -> {Enum.count(l, &(&1 == "0")), l} end)
    |> Enum.min()
    |> elem(1)
    |> (fn l -> Enum.count(l, &(&1 == "1")) * Enum.count(l, &(&1 == "2")) end).()
    |> IO.puts()

  ["2"] ->
    layers
    |> Enum.reduce(List.duplicate([], width * height), fn l, px ->
      Enum.with_index(l)
      |> Enum.reduce(px, fn {x, i}, px ->
        List.replace_at(px, i, Enum.at(px, i) ++ [x])
      end)
    end)
    |> Enum.reduce([], fn px, img ->
      [
        Enum.reduce_while(px, 0, fn x, _ -> if x == "2", do: {:cont, x}, else: {:halt, x} end)
        | img
      ]
    end)
    |> Enum.chunk_every(width)
    |> Enum.reverse()
    |> Enum.map(
      &(Enum.map(&1, fn x -> if x == "0", do: " ", else: "#" end)
        |> Enum.reverse()
        |> Enum.join(" "))
    )
    |> Enum.join("\n")
    |> IO.puts()
end
