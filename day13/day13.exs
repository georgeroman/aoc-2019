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

  def runOpcodes(opcodes, i, base, input \\ nil) do
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
  File.read!("day13.input")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index(0)
    |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

getJoystickTilt = fn tiles ->
  ballX = tiles |> Enum.find(fn {_, id} -> id == 4 end)
  paddleX = tiles |> Enum.find(fn {_, id} -> id == 3 end)
  if ballX == nil or paddleX == nil do
    nil
  else
    ballX = ballX |> elem(0) |> elem(0)
    paddleX = paddleX |> elem(0) |> elem(0)
    cond do
      ballX - paddleX == 0 -> 0
      ballX - paddleX < 0 -> -1
      ballX - paddleX > 0 -> 1
    end
  end
end

runArcade = fn opcodes ->
  Stream.iterate({:ok, opcodes, 0, 0, 0, %{}}, fn {_, opcodes, lastIndex, base, highestScore, tiles} ->
    {ok, opcodes, x, lastIndex, base} = Day11.runOpcodes(opcodes, lastIndex, base, getJoystickTilt.(tiles))
    if ok == :halt do
      {ok, opcodes, lastIndex, base, highestScore, tiles}
    else
      {ok, opcodes, y, lastIndex, base} = Day11.runOpcodes(opcodes, lastIndex, base, getJoystickTilt.(tiles))
      if ok == :halt do
        {ok, opcodes, lastIndex, base, highestScore, tiles}
        else
        if x == -1 and y == 0 do
          {ok, opcodes, score, lastIndex, base} = Day11.runOpcodes(opcodes, lastIndex, base, getJoystickTilt.(tiles))
          {ok, opcodes, lastIndex, base, max(score, highestScore), tiles}
        else
          {ok, opcodes, id, lastIndex, base} = Day11.runOpcodes(opcodes, lastIndex, base, getJoystickTilt.(tiles))
          {ok, opcodes, lastIndex, base, highestScore, Map.put(tiles, {x, y}, id)}
        end
      end
    end
  end) |> Enum.find(&(&1 |> elem(0) == :halt))
end

case System.argv() do
  ["1"] ->
    opcodes
      |> runArcade.()
      |> elem(4)
      |> Map.values
      |> Enum.filter(fn id -> id == 2 end)
      |> length
      |> IO.puts

  ["2"] ->
    opcodes
      |> Map.put(0, 2)
      |> runArcade.()
      |> elem(4)
      |> IO.puts
end
