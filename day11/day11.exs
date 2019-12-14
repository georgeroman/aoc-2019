defmodule Day11 do
  defp selectModeIn(opcodes, modes, base, i, count) do
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

  defp selectModeOut(opcodes, modes, base, i, count) do
    if length(modes) > count and Enum.at(modes, count) == "2" do
      base + (opcodes[i] || 0)
    else
      opcodes[i] || 0
    end
  end

  def runOpcodes(opcodes, i, base, input) do
    sOpcode = Integer.to_string(opcodes[i])
    opcode = (if String.length(sOpcode) >= 2, do: String.slice(sOpcode, -2..-1), else: sOpcode) |> String.to_integer
    modes = Regex.scan(~r/./, sOpcode |> String.slice(0..-3)) |> List.flatten |> Enum.reverse

    case opcode do
      1 ->
        op1 = selectModeIn(opcodes, modes, base, i + 1, 0)
        op2 = selectModeIn(opcodes, modes, base, i + 2, 1)
        out = selectModeOut(opcodes, modes, base, i + 3, 2)
        runOpcodes(Map.put(opcodes, out, op1 + op2), i + 4, base, input)
         
      2 ->
        op1 = selectModeIn(opcodes, modes, base, i + 1, 0)
        op2 = selectModeIn(opcodes, modes, base, i + 2, 1)
        out = selectModeOut(opcodes, modes, base, i + 3, 2)
        runOpcodes(Map.put(opcodes, out, op1 * op2), i + 4, base, input)

      3 ->
        out = selectModeOut(opcodes, modes, base, i + 1, 0)
        runOpcodes(Map.put(opcodes, out, input), i + 2, base, input)

      4 ->
        output = selectModeIn(opcodes, modes, base, i + 1, 0)
        {:ok, opcodes, output, i + 2, base}

      5 ->
        op1 = selectModeIn(opcodes, modes, base, i + 1, 0)
        op2 = selectModeIn(opcodes, modes, base, i + 2, 1)
        runOpcodes(opcodes, if op1 != 0 do op2 else i + 3 end, base, input)

      6 ->
        op1 = selectModeIn(opcodes, modes, base, i + 1, 0)
        op2 = selectModeIn(opcodes, modes, base, i + 2, 1)
        runOpcodes(opcodes, if op1 == 0 do op2 else i + 3 end, base, input)

      7 ->
        op1 = selectModeIn(opcodes, modes, base, i + 1, 0)
        op2 = selectModeIn(opcodes, modes, base, i + 2, 1)
        out = selectModeOut(opcodes, modes, base, i + 3, 2)
        runOpcodes(Map.put(opcodes, out, if op1 < op2 do 1 else 0 end), i + 4, base, input)

      8 ->
        op1 = selectModeIn(opcodes, modes, base, i + 1, 0)
        op2 = selectModeIn(opcodes, modes, base, i + 2, 1)
        out = selectModeOut(opcodes, modes, base, i + 3, 2)
        runOpcodes(Map.put(opcodes, out, if op1 == op2 do 1 else 0 end), i + 4, base, input)

      9 ->
        param = selectModeIn(opcodes, modes, base, i + 1, 0)
        runOpcodes(opcodes, i + 2, base + param, input)

      99 ->
        {:halt, nil, nil, -1, -1}
    end
  end
end

opcodes =
  File.read!("day11.input")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index(0)
    |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

paint = fn startColor ->
  Stream.iterate({:ok, opcodes, 0, 0, Map.put(%{}, {0, 0}, startColor), "up", {0, 0}}, fn {_, opcodes, lastIndex, base, colors, facing, {x, y}} ->
    currentColor = Map.get(colors, {x, y}, 0)
    {ok, opcodes, color, lastIndex, base} = Day11.runOpcodes(opcodes, lastIndex, base, currentColor)

    if ok == :halt do
      {ok, opcodes, lastIndex, base, colors, facing, {x, y}}
    else
      {ok, opcodes, direction, lastIndex, base} = Day11.runOpcodes(opcodes, lastIndex, base, color)

      {facing, {newX, newY}} =
        case {direction, facing} do
          {0, "up"} -> {"left", {x - 1, y}}
          {1, "up"} -> {"right", {x + 1, y}}
          {0, "left"} -> {"down", {x, y + 1}}
          {1, "left"} -> {"up", {x, y - 1}}
          {0, "right"} -> {"up", {x, y - 1}}
          {1, "right"} -> {"down", {x, y + 1}}
          {0, "down"} -> {"right", {x + 1, y}}
          {1, "down"} -> {"left", {x - 1, y}}
        end

      {ok, opcodes, lastIndex, base, Map.put(colors, {x, y}, color), facing, {newX, newY}}
    end
  end) |> Enum.find(&(&1 |> elem(0) == :halt))
end

case System.argv() do
  ["1"] ->
    paint.(0)
      |> elem(4)
      |> map_size
      |> IO.inspect

  ["2"] ->
    colors = paint.(1) |> elem(4)
    whiteColored = Enum.filter(Map.keys(colors), fn {x, y} -> colors[{x, y}] == 1 end)

    xSorted = Enum.sort(whiteColored, fn ({x1, _}, {x2, _}) -> x1 < x2 end)
    {minX, maxX} = {List.first(xSorted) |> elem(0), List.last(xSorted) |> elem(0)}

    ySorted = Enum.sort(whiteColored, fn ({_, y1}, {_, y2}) -> y1 < y2 end)
    {minY, maxY} = {List.first(ySorted) |> elem(1), List.last(ySorted) |> elem(1)}

    IO.puts(
      Enum.join(
        for y <- minY..maxY do
          Enum.join(
            Enum.map(
              for x <- minX..maxX do
                colors[{x, y}] 
              end,
              fn color -> if color == 0, do: " ", else: "#" end),
              " ")
        end,
        "\n"))
end
