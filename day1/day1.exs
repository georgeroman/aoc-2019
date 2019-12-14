masses =
  File.stream!("day1.input")
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.to_integer/1)

case System.argv() do
  ["1"] ->
    masses
      |> Stream.map(&(div(&1, 3) - 2))
      |> Enum.reduce(0, &+/2)
      |> IO.puts

  ["2"] ->
    masses
      |> Stream.map(fn mass ->
           Stream.iterate(mass, &(div(&1, 3) - 2))
           |> Stream.drop(1)
           |> Stream.take_while(&(&1 > 0))
           |> Enum.sum
         end)
      |> Enum.reduce(0, &+/2)
      |> IO.puts
end
