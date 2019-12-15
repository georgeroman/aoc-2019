defmodule Day15 do
  defp select_mode_in(opcodes, modes, base, i, count) do
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
    s_opcode = Integer.to_string(opcodes[i])

    opcode =
      if(String.length(s_opcode) >= 2, do: String.slice(s_opcode, -2..-1), else: s_opcode)
      |> String.to_integer()

    modes = Regex.scan(~r/./, s_opcode |> String.slice(0..-3)) |> List.flatten() |> Enum.reverse()

    case opcode do
      1 ->
        op1 = select_mode_in(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_in(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)
        run_opcodes(Map.put(opcodes, out, op1 + op2), i + 4, base, input)

      2 ->
        op1 = select_mode_in(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_in(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)
        run_opcodes(Map.put(opcodes, out, op1 * op2), i + 4, base, input)

      3 ->
        out = select_mode_out(opcodes, modes, base, i + 1, 0)
        run_opcodes(Map.put(opcodes, out, input), i + 2, base, input)

      4 ->
        output = select_mode_in(opcodes, modes, base, i + 1, 0)
        {:ok, opcodes, output, i + 2, base}

      5 ->
        op1 = select_mode_in(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_in(opcodes, modes, base, i + 2, 1)

        run_opcodes(
          opcodes,
          if op1 != 0 do
            op2
          else
            i + 3
          end,
          base,
          input
        )

      6 ->
        op1 = select_mode_in(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_in(opcodes, modes, base, i + 2, 1)

        run_opcodes(
          opcodes,
          if op1 == 0 do
            op2
          else
            i + 3
          end,
          base,
          input
        )

      7 ->
        op1 = select_mode_in(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_in(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)

        run_opcodes(
          Map.put(
            opcodes,
            out,
            if op1 < op2 do
              1
            else
              0
            end
          ),
          i + 4,
          base,
          input
        )

      8 ->
        op1 = select_mode_in(opcodes, modes, base, i + 1, 0)
        op2 = select_mode_in(opcodes, modes, base, i + 2, 1)
        out = select_mode_out(opcodes, modes, base, i + 3, 2)

        run_opcodes(
          Map.put(
            opcodes,
            out,
            if op1 == op2 do
              1
            else
              0
            end
          ),
          i + 4,
          base,
          input
        )

      9 ->
        param = select_mode_in(opcodes, modes, base, i + 1, 0)
        run_opcodes(opcodes, i + 2, base + param, input)

      99 ->
        {:halt, nil, nil, -1, -1}
    end
  end

  def bfs(q, visited, until_empty \\ false) do
    {{:value, {{x, y}, steps, opcodes, last_index, base}}, q} = :queue.out(q)
    visited = MapSet.put(visited, {x, y})

    {_, opcodes_north, status_north, last_index_north, base_north} =
      run_opcodes(opcodes, last_index, base, 1)

    {_, opcodes_south, status_south, last_index_south, base_south} =
      run_opcodes(opcodes, last_index, base, 2)

    {_, opcodes_west, status_west, last_index_west, base_west} =
      run_opcodes(opcodes, last_index, base, 3)

    {_, opcodes_east, status_east, last_index_east, base_east} =
      run_opcodes(opcodes, last_index, base, 4)

    q =
      if status_north == 1 and not MapSet.member?(visited, {x, y + 1}),
        do: :queue.in({{x, y + 1}, steps + 1, opcodes_north, last_index_north, base_north}, q),
        else: q

    q =
      if status_south == 1 and not MapSet.member?(visited, {x, y - 1}),
        do: :queue.in({{x, y - 1}, steps + 1, opcodes_south, last_index_south, base_south}, q),
        else: q

    q =
      if status_west == 1 and not MapSet.member?(visited, {x - 1, y}),
        do: :queue.in({{x - 1, y}, steps + 1, opcodes_west, last_index_west, base_west}, q),
        else: q

    q =
      if status_east == 1 and not MapSet.member?(visited, {x + 1, y}),
        do: :queue.in({{x + 1, y}, steps + 1, opcodes_east, last_index_east, base_east}, q),
        else: q

    if not until_empty do
      if status_north == 2 or status_south == 2 or status_west == 2 or status_east == 2 do
        {opcodes, last_index, base, steps + 1}
      else
        bfs(q, visited, until_empty)
      end
    else
      if :queue.is_empty(q), do: steps + 1, else: bfs(q, visited, until_empty)
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
    {_, _, _, steps} =
      Day15.bfs(:queue.in({{0, 0}, 0, opcodes, 0, 0}, :queue.new()), MapSet.new())

    IO.puts(steps)

  ["2"] ->
    {opcodes, last_index, base, _} =
      Day15.bfs(:queue.in({{0, 0}, 0, opcodes, 0, 0}, :queue.new()), MapSet.new())

    steps =
      Day15.bfs(
        :queue.in({{0, 0}, 0, opcodes, last_index, base}, :queue.new()),
        MapSet.new(),
        true
      )

    IO.puts(steps)
end
