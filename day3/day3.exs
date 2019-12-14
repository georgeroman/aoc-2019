[wire1, wire2] =
  File.read!("day3.input")
    |> String.split("\n")
    |> Enum.take(2)
    |> Enum.map(&(String.split(&1, ",")))

generatePoints = fn wire ->
  Enum.reduce(wire, {{1, 1}, 0, MapSet.new(), Map.new()}, fn (data, {{x, y}, step, positions, positionsStep}) ->
    direction = String.at(data, 0)
    steps = String.slice(data, 1..-1) |> String.to_integer 

    Enum.reduce(1..steps, {{x, y}, step, positions, positionsStep}, fn (_, {{x, y}, step, positions, positionsStep}) ->
      case direction do
        "R" ->
          {{x + 1, y}, step + 1, MapSet.put(positions, {x + 1, y}), Map.put(positionsStep, {x + 1, y}, step + 1)}

        "U" ->
          {{x, y + 1}, step + 1, MapSet.put(positions, {x, y + 1}), Map.put(positionsStep, {x, y + 1}, step + 1)}

        "L" ->
          {{x - 1, y}, step + 1, MapSet.put(positions, {x - 1, y}), Map.put(positionsStep, {x - 1, y}, step + 1)}

        "D" ->
          {{x, y - 1}, step + 1, MapSet.put(positions, {x, y - 1}), Map.put(positionsStep, {x, y - 1}, step + 1)}
      end
    end)
  end)
end

wire1Points = generatePoints.(wire1)
wire2Points = generatePoints.(wire2)
commonPoints = MapSet.intersection(wire1Points |> elem(2), wire2Points |> elem(2))

case System.argv() do
  ["1"] ->
    Enum.reduce(commonPoints, 99999999, fn ({x, y}, distance) ->
      min(abs(x - 1) + abs(y - 1), distance)
    end) |> IO.puts

  ["2"] ->
    Enum.reduce(commonPoints, 99999999, fn ({x, y}, steps) ->
      min(steps, (wire1Points |> elem(3) |> Map.get({x, y})) + (wire2Points |> elem(3) |> Map.get({x, y}))) 
    end) |> IO.puts
end
