defmodule Day6 do
  def calculate_num_orbits(centers, center, num_orbits, prevs) do
    if not Map.has_key?(centers, center) do
      {num_orbits, prevs}
    else
      Enum.reduce(centers[center], {num_orbits, prevs}, fn orbit, {num_orbits, prevs} ->
        calculate_num_orbits(
          centers,
          orbit,
          Map.put(num_orbits, orbit, Map.get(num_orbits, center, 0) + 1),
          Map.put(prevs, orbit, center)
        )
      end)
    end
  end
end

data =
  File.stream!("day6.input")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.split/1)
  |> List.flatten()
  |> Enum.map(fn s -> String.split(s, ")") |> List.flatten() end)
  |> Enum.reduce(%{}, fn [center, orbit], centers ->
    Map.put(centers, center, [orbit | Map.get(centers, center, [])])
  end)
  |> Day6.calculate_num_orbits("COM", %{}, %{})

case System.argv() do
  ["1"] ->
    data |> elem(0) |> Map.values() |> Enum.sum() |> IO.puts()

  ["2"] ->
    prevs = data |> elem(1)

    you_prevs =
      Stream.iterate("YOU", fn curr -> prevs[curr] end)
      |> Enum.take_while(fn elem -> elem != "COM" end)

    san_prevs =
      Stream.iterate("SAN", fn curr -> prevs[curr] end)
      |> Enum.take_while(fn elem -> elem != "COM" end)

    first_common = Enum.find(you_prevs, fn elem -> Enum.find(san_prevs, &(&1 == elem)) end)

    num_orbits = data |> elem(0)

    IO.puts(
      num_orbits["YOU"] - num_orbits[first_common] +
        (num_orbits["SAN"] - num_orbits[first_common]) - 2
    )
end
