defmodule Day2 do
  def runOpcodes(opcodes, i) do
    case opcodes[i] do
      1 ->
        op1 = opcodes[opcodes[i + 1]]
        op2 = opcodes[opcodes[i + 2]]
        out = opcodes[i + 3]
        runOpcodes(Map.put(opcodes, out, op1 + op2), i + 4)
         
      2 ->
        op1 = opcodes[opcodes[i + 1]]
        op2 = opcodes[opcodes[i + 2]]
        out = opcodes[i + 3]
        runOpcodes(Map.put(opcodes, out, op1 * op2), i + 4)

      99 ->
        opcodes
    end
  end
end

opcodes =
  File.read!("day2.input")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)

opcodes =
  Stream.with_index(opcodes, 0)
    |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

case System.argv() do
  ["1"] ->
    opcodes
      |> Map.put(1, 12)
      |> Map.put(2, 2)
      |> Day2.runOpcodes(0)
      |> Map.get(0)
      |> IO.puts

  ["2"] ->
    try do
      for noun <- 0..99, verb <- 0..99 do
        first =
          opcodes
            |> Map.put(1, noun)
            |> Map.put(2, verb)
            |> Day2.runOpcodes(0)
            |> Map.get(0)

        if first == 19690720, do: throw(noun * 100 + verb)
      end
    catch
      result -> IO.puts result
    end
end
