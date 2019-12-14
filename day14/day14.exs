defmodule Day14 do
  def getOresIfTerminal(current, producedBy) do
    first = Enum.at(producedBy[current], 0)
    if elem(first, 1) == "ORE", do: elem(first, 0), else: 0
  end

  def calculateNeededForFuel(current, needed, numProduced, producedBy, totalSoFar, extra) do
    if current == "ORE" do
      {totalSoFar, extra}
    else
      cond do
        # We have enough extra of this chemical
        Map.get(extra, current, 0) >= needed ->
          {totalSoFar, Map.put(extra, current, Map.get(extra, current, 0) - needed)}

        true ->
          multiplier = ceil((needed - Map.get(extra, current, 0)) / numProduced[current])
          totalSoFar = totalSoFar + multiplier * getOresIfTerminal(current, producedBy)
          extra = Map.put(extra, current, Map.get(extra, current, 0) - (needed - multiplier * numProduced[current]))

          Enum.reduce(producedBy[current], {totalSoFar, extra}, fn ({needed, by}, {totalSoFar, extra}) ->
            calculateNeededForFuel(by, multiplier * needed, numProduced, producedBy, totalSoFar, extra)
          end)
      end
    end
  end

  def fuelForOres(ores, startFuel, endFuel, numProduced, producedBy) do
    if startFuel >= endFuel do
      endFuel
    else
      midFuel = div(startFuel + endFuel, 2)
      if calculateNeededForFuel("FUEL", midFuel, numProduced, producedBy, 0, %{}) |> elem(0) > ores do
        fuelForOres(ores, startFuel, midFuel - 1, numProduced, producedBy)
      else
        fuelForOres(ores, midFuel + 1, endFuel, numProduced, producedBy)
      end
    end
  end
end

{numProduced, producedBy} =
  File.stream!("day14.input")
    |> Enum.map(fn line ->
         chemicals =
           Regex.scan(~r/(\d+) ([A-Z]+)/, line)
             |> Enum.map(fn [_, count, chemical] -> {String.to_integer(count), chemical} end)
         {Enum.at(chemicals, -1), Enum.slice(chemicals, 0..-2)}
       end)
    |> Enum.reduce({%{}, %{}}, fn ({{countProduced, produced}, producers}, {numProduced, producedBy}) ->
         numProduced = Map.put(numProduced, produced, countProduced)
         producedBy = Map.put(producedBy, produced, producers)
         {numProduced, producedBy} 
       end)

case System.argv() do
  ["1"] ->
    Day14.calculateNeededForFuel("FUEL", 1, numProduced, producedBy, 0, %{})
      |> elem(0)
      |> IO.puts

  ["2"] ->
    trillion = 1000000000000
    startFuel = div(trillion, Day14.calculateNeededForFuel("FUEL", 1, numProduced, producedBy, 0, %{}) |> elem(0))
    endFuel =
      Stream.iterate(startFuel, fn fuel -> fuel + startFuel end)
        |> Enum.find(fn fuel -> Day14.calculateNeededForFuel("FUEL", fuel, numProduced, producedBy, 0, %{}) |> elem(0) > trillion end)

    Day14.fuelForOres(trillion, startFuel, endFuel, numProduced, producedBy)
      |> IO.puts
end
