defmodule Day7 do
  def runOpcodes(opcodes, i, inputs) do
    sOpcode = Integer.to_string(opcodes[i])
    opcode = (if String.length(sOpcode) >= 2, do: String.slice(sOpcode, -2..-1), else: sOpcode) |> String.to_integer
    modes = Regex.scan(~r/./, sOpcode |> String.slice(0..-3)) |> List.flatten |> Enum.reverse

    case opcode do
      1 ->
        op1 = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        op2 = if length(modes) > 1 and Enum.at(modes, 1) == "1", do: opcodes[i + 2], else: opcodes[opcodes[i + 2]]
        out = opcodes[i + 3]
        runOpcodes(Map.put(opcodes, out, op1 + op2), i + 4, inputs)
         
      2 ->
        op1 = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        op2 = if length(modes) > 1 and Enum.at(modes, 1) == "1", do: opcodes[i + 2], else: opcodes[opcodes[i + 2]]
        out = opcodes[i + 3]
        runOpcodes(Map.put(opcodes, out, op1 * op2), i + 4, inputs)

      3 ->
        out = opcodes[i + 1]
        runOpcodes(Map.put(opcodes, out, List.first(inputs)), i + 2, Enum.drop(inputs, 1))

      4 ->
        output = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        {:ok, output, i + 2}

      5 ->
        op1 = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        op2 = if length(modes) > 1 and Enum.at(modes, 1) == "1", do: opcodes[i + 2], else: opcodes[opcodes[i + 2]]
        runOpcodes(opcodes, if op1 != 0 do op2 else i + 3 end, inputs)

      6 ->
        op1 = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        op2 = if length(modes) > 1 and Enum.at(modes, 1) == "1", do: opcodes[i + 2], else: opcodes[opcodes[i + 2]]
        runOpcodes(opcodes, if op1 == 0 do op2 else i + 3 end, inputs)

      7 ->
        op1 = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        op2 = if length(modes) > 1 and Enum.at(modes, 1) == "1", do: opcodes[i + 2], else: opcodes[opcodes[i + 2]]
        out = opcodes[i + 3]
        runOpcodes(Map.put(opcodes, out, if op1 < op2 do 1 else 0 end), i + 4, inputs)

      8 ->
        op1 = if length(modes) > 0 and Enum.at(modes, 0) == "1", do: opcodes[i + 1], else: opcodes[opcodes[i + 1]]
        op2 = if length(modes) > 1 and Enum.at(modes, 1) == "1", do: opcodes[i + 2], else: opcodes[opcodes[i + 2]]
        out = opcodes[i + 3]
        runOpcodes(Map.put(opcodes, out, if op1 == op2 do 1 else 0 end), i + 4, inputs)

      99 ->
        {:halt, nil, -1}
    end
  end

  def runAllConfigs(opcodes, phaseSettings, prevMax, feedback \\ false) do
    if length(phaseSettings) == 5 do
      if feedback do
        max(
          prevMax,
          Stream.iterate({:ok, 0, %{}, %{}}, fn {_, input, lastIndices, settingInputConsumed} ->
            Enum.reduce(phaseSettings, {:ok, input, lastIndices, settingInputConsumed}, fn (setting, {result, input, lastIndices, settingInputConsumed}) ->
              {newResult, output, lastIndex} =
                runOpcodes(
                  opcodes,
                  Map.get(lastIndices, setting, 0),
                  if not Map.has_key?(settingInputConsumed, setting) do [setting, input] else [input] end)
              {
                (if result == :halt, do: :halt, else: newResult),
                output,
                Map.put(lastIndices, setting, lastIndex),
                Map.put(settingInputConsumed, setting, true)
              }
            end)
          end)
            |> Enum.take_while(fn {result, _, _, _} -> result != :halt end)
            |> Enum.max
            |> elem(1))
      else
        max(
          prevMax,
          Enum.reduce(phaseSettings, 0, fn (setting, input) ->
            runOpcodes(opcodes, 0, [setting, input]) |> elem(1)
          end))
      end
    else
      Enum.max(for setting <- if feedback, do: 5..9, else: 0..4 do
        if not Enum.member?(phaseSettings, setting) do
          runAllConfigs(opcodes, phaseSettings ++ [setting], prevMax, feedback)
        else
          prevMax
        end
      end)
    end
  end
end

opcodes =
  File.read!("day7.input")
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
    |> Enum.with_index(0)
    |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

case System.argv() do
  ["1"] ->
    opcodes
      |> Day7.runAllConfigs([], 0)
      |> IO.puts

  ["2"] ->
    opcodes
      |> Day7.runAllConfigs([], 0, true)
      |> IO.puts
end
