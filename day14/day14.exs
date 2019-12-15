defmodule Day14 do
  def get_ores_if_terminal(current, produced_by) do
    first = Enum.at(produced_by[current], 0)
    if elem(first, 1) == "ORE", do: elem(first, 0), else: 0
  end

  def calculate_needed_for_fuel(current, needed, num_produced, produced_by, total_so_far, extra) do
    if current == "ORE" do
      {total_so_far, extra}
    else
      cond do
        # We have enough extra of this chemical
        Map.get(extra, current, 0) >= needed ->
          {total_so_far, Map.put(extra, current, Map.get(extra, current, 0) - needed)}

        # We don't have enough extra
        true ->
          multiplier = ceil((needed - Map.get(extra, current, 0)) / num_produced[current])
          total_so_far = total_so_far + multiplier * get_ores_if_terminal(current, produced_by)

          extra =
            Map.put(
              extra,
              current,
              Map.get(extra, current, 0) - (needed - multiplier * num_produced[current])
            )

          Enum.reduce(produced_by[current], {total_so_far, extra}, fn {needed, by},
                                                                      {total_so_far, extra} ->
            calculate_needed_for_fuel(
              by,
              multiplier * needed,
              num_produced,
              produced_by,
              total_so_far,
              extra
            )
          end)
      end
    end
  end

  def fuel_for_ores(ores, start_fuel, end_fuel, num_produced, produced_by) do
    if start_fuel >= end_fuel do
      end_fuel
    else
      midFuel = div(start_fuel + end_fuel, 2)

      if calculate_needed_for_fuel("FUEL", midFuel, num_produced, produced_by, 0, %{}) |> elem(0) >
           ores do
        fuel_for_ores(ores, start_fuel, midFuel - 1, num_produced, produced_by)
      else
        fuel_for_ores(ores, midFuel + 1, end_fuel, num_produced, produced_by)
      end
    end
  end
end

{num_produced, produced_by} =
  File.stream!("day14.input")
  |> Enum.map(fn line ->
    chemicals =
      Regex.scan(~r/(\d+) ([A-Z]+)/, line)
      |> Enum.map(fn [_, count, chemical] -> {String.to_integer(count), chemical} end)

    {Enum.at(chemicals, -1), Enum.slice(chemicals, 0..-2)}
  end)
  |> Enum.reduce({%{}, %{}}, fn {{count_produced, produced}, producers},
                                {num_produced, produced_by} ->
    num_produced = Map.put(num_produced, produced, count_produced)
    produced_by = Map.put(produced_by, produced, producers)
    {num_produced, produced_by}
  end)

case System.argv() do
  ["1"] ->
    Day14.calculate_needed_for_fuel("FUEL", 1, num_produced, produced_by, 0, %{})
    |> elem(0)
    |> IO.puts()

  ["2"] ->
    trillion = 1_000_000_000_000

    start_fuel =
      div(
        trillion,
        Day14.calculate_needed_for_fuel("FUEL", 1, num_produced, produced_by, 0, %{}) |> elem(0)
      )

    end_fuel =
      Stream.iterate(start_fuel, fn fuel -> fuel + start_fuel end)
      |> Enum.find(fn fuel ->
        Day14.calculate_needed_for_fuel("FUEL", fuel, num_produced, produced_by, 0, %{})
        |> elem(0) >
          trillion
      end)

    Day14.fuel_for_ores(trillion, start_fuel, end_fuel, num_produced, produced_by)
    |> IO.puts()
end
