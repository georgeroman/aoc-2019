defmodule Day6 do
  def calculateNumOrbits(centers, center, numOrbits, prevs) do
    if not Map.has_key?(centers, center) do
      {numOrbits, prevs}
    else
      Enum.reduce(centers[center], {numOrbits, prevs}, fn (orbit, {numOrbits, prevs}) ->
        calculateNumOrbits(centers, orbit, Map.put(numOrbits, orbit, Map.get(numOrbits, center, 0) + 1), Map.put(prevs, orbit, center))
      end)
    end
  end
end

data = 
  File.read!("day6.input")
    |> String.split("\n")
    |> Enum.map(&String.split/1)
    |> List.flatten
    |> Enum.map(fn s -> String.split(s, ")") |> List.flatten end)
    |> Enum.reduce(%{}, fn ([center, orbit], centers) -> Map.put(centers, center, [orbit | Map.get(centers, center, [])]) end)
    |> Day6.calculateNumOrbits("COM", %{}, %{})

case System.argv() do
  ["1"] ->
    data |> elem(0) |> Map.values |> Enum.sum |> IO.puts

  ["2"] ->
    prevs = data |> elem(1) 
    youPrevs = Stream.iterate("YOU", fn curr -> prevs[curr] end) |> Enum.take_while(fn elem -> elem != "COM" end)
    sanPrevs = Stream.iterate("SAN", fn curr -> prevs[curr] end) |> Enum.take_while(fn elem -> elem != "COM" end)
    firstCommon = Enum.find(youPrevs, fn elem -> Enum.find(sanPrevs, &(&1 == elem)) end)

    numOrbits = data |> elem(0)
    IO.puts((numOrbits["YOU"] - numOrbits[firstCommon]) + (numOrbits["SAN"] - numOrbits[firstCommon]) - 2)
end
