defmodule Day15 do
  defp select_mode_id(opcodes, modes, base, i, count) do
    if length(modes) > count do
      case Enum.at(modes, count) do
        "1" -> opcodes[i] || 0
        "2" -> opcodes[base + (opcodes[i] || 0)] || 0
        _ -> opcodes[opcodes[i]] || 0
      end
    else
      opcodes[opcodes[i]] || 0
    end
  end

  defp select_mode_out(opcodes, modes, base, i, count) do
    if length(modes) > count and Enum.at(modes, count) == "2" do
      base + (opcodes[i] || 0)
    else
      opcodes[i] || 0
    end
  end

  def run_opcodes(opcodes, i, base, input \\ nil) do
    sOpcode = Integer.to_string(opcodes[i])
    opcode = (if String.length(sOpcode) >= 2, do: String.slice(sOpcode, -2..-1), else: sOpcode) |> String.to_integer()
    modes = Regex.scan(~r/./, sOpcode |> String.slice(0..-3)) |> List.flatten() |> Enum.reverse()

    case opcode do
      1 ->
        op1 = select_mode_id(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_id(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)
        run_opcodes(Map.put(opcodes, out, op1 + op2), i + 4, base, input)

      2 ->
        op1 = select_mode_id(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_id(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)
        run_opcodes(Map.put(opcodes, out, op1 * op2), i + 4, base, input)

      3 ->
        out = select_mode_out(opcodes, modes, base, i + 1, 0)
        run_opcodes(Map.put(opcodes, out, input), i + 2, base, input)

      4 ->
        output = select_mode_id(opcodes, modes, base, i + 1, 0)
        {:ok, opcodes, output, i + 2, base}

      5 ->
        op1 = select_mode_id(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_id(opcodes, modes, base, i + 2, 1)
        run_opcodes(opcodes, if op1 != 0 do op2 else i + 3 end, base, input)

      6 ->
        op1 = select_mode_id(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_id(opcodes, modes, base, i + 2, 1)
        run_opcodes(opcodes, if op1 == 0 do op2 else i + 3 end, base, input)

      7 ->
        op1 = select_mode_id(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_id(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)
        run_opcodes(Map.put(opcodes, out, if op1 < op2 do 1 else 0 end), i + 4, base, input)

      8 ->
        op1 = select_mode_id(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_id(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)
        run_opcodes(Map.put(opcodes, out, if op1 == op2 do 1 else 0 end), i + 4, base, input)

      9 ->
        param = select_mode_id(opcodes, modes, base, i + 1, 0)
        run_opcodes(opcodes, i + 2, base + param, input)

      99 ->
        {:halt, nil, nil, -1, -1}
    end
  end

  def bfs(q, visited, untilEmpty \\ false) do
    {{:value, {{x, y}, steps, opcodes, lastIndex, base}}, q} = :queue.out(q)
    visited = MapSet.put(visited, {x, y})

    {_, opcodesNorth, statusNorth, lastIndexNorth, baseNorth} = run_opcodes(opcodes, lastIndex, base, 1)
    {_, opcodesSouth, statusSouth, lastIndexSouth, baseSouth} = run_opcodes(opcodes, lastIndex, base, 2)
    {_, opcodesWest, statusWest, lastIndexWest, baseWest} = run_opcodes(opcodes, lastIndex, base, 3)
    {_, opcodesEast, statusEast, lastIndexEast, baseEast} = run_opcodes(opcodes, lastIndex, base, 4)

    q = if statusNorth == 1 and not MapSet.member?(visited, {x, y + 1}),
          do: :queue.in({{x, y + 1}, steps + 1, opcodesNorth, lastIndexNorth, baseNorth}, q), else: q
    q = if statusSouth == 1 and not MapSet.member?(visited, {x, y - 1}),
          do: :queue.in({{x, y - 1}, steps + 1, opcodesSouth, lastIndexSouth, baseSouth}, q), else: q
    q = if statusWest == 1 and not MapSet.member?(visited, {x - 1, y}),
          do: :queue.in({{x - 1, y}, steps + 1, opcodesWest, lastIndexWest, baseWest}, q), else: q
    q = if statusEast == 1 and not MapSet.member?(visited, {x + 1, y}),
          do: :queue.in({{x + 1, y}, steps + 1, opcodesEast, lastIndexEast, baseEast}, q), else: q

    if not untilEmpty do
      if statusNorth == 2 or statusSouth == 2 or statusWest == 2 or statusEast == 2 do
        {opcodes, lastIndex, base, steps + 1}
      else
        bfs(q, visited, untilEmpty)
      end
    else
      if :queue.is_empty(q), do: steps + 1, else: bfs(q, visited, untilEmpty)
    end
  end
end

opcodes =
  File.read!("day15.input")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index(0)
    |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

case System.argv() do
  ["1"] ->
    {_, _, _, steps} = Day15.bfs(:queue.in({{0, 0}, 0, opcodes, 0, 0}, :queue.new()), MapSet.new())
    IO.puts(steps)

  ["2"] ->
    {opcodes, lastIndex, base, _} = Day15.bfs(:queue.in({{0, 0}, 0, opcodes, 0, 0}, :queue.new()), MapSet.new())
    steps = Day15.bfs(:queue.in({{0, 0}, 0, opcodes, lastIndex, base}, :queue.new()), MapSet.new(), true)
    IO.puts(steps)
end
