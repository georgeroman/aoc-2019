[wire1, wire2] =
  File.stream!("day3.input")
  |> Enum.map(fn line -> line |> String.trim() |> String.split(",") end)

generate_points = fn wire ->
  Enum.reduce(wire, {{1, 1}, 0, MapSet.new(), Map.new()}, fn data,
                                                             {{x, y}, step, positions,
                                                              positions_step} ->
    direction = String.at(data, 0)
    steps = String.slice(data, 1..-1) |> String.to_integer()

    Enum.reduce(1..steps, {{x, y}, step, positions, positions_step}, fn _,
                                                                        {{x, y}, step, positions,
                                                                         positions_step} ->
      case direction do
        "R" ->
          {{x + 1, y}, step + 1, MapSet.put(positions, {x + 1, y}),
           Map.put(positions_step, {x + 1, y}, step + 1)}

        "U" ->
          {{x, y + 1}, step + 1, MapSet.put(positions, {x, y + 1}),
           Map.put(positions_step, {x, y + 1}, step + 1)}

        "L" ->
          {{x - 1, y}, step + 1, MapSet.put(positions, {x - 1, y}),
           Map.put(positions_step, {x - 1, y}, step + 1)}

        "D" ->
          {{x, y - 1}, step + 1, MapSet.put(positions, {x, y - 1}),
           Map.put(positions_step, {x, y - 1}, step + 1)}
      end
    end)
  end)
end

wire1_points = generate_points.(wire1)
wire2_points = generate_points.(wire2)
common_points = MapSet.intersection(wire1_points |> elem(2), wire2_points |> elem(2))

case System.argv() do
  ["1"] ->
    Enum.reduce(common_points, 99_999_999, fn {x, y}, distance ->
      min(abs(x - 1) + abs(y - 1), distance)
    end)
    |> IO.puts()

  ["2"] ->
    Enum.reduce(common_points, 99_999_999, fn {x, y}, steps ->
      min(
        steps,
        (wire1_points |> elem(3) |> Map.get({x, y})) +
          (wire2_points |> elem(3) |> Map.get({x, y}))
      )
    end)
    |> IO.puts()
end
