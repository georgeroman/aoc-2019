defmodule Day5 do
  def run_opcodes(opcodes, i, input) do
    s_opcode = Integer.to_string(opcodes[i])

    opcode =
      if(String.length(s_opcode) >= 2, do: String.slice(s_opcode, -2..-1), else: s_opcode)
      |> String.to_integer()

    modes = Regex.scan(~r/./, s_opcode |> String.slice(0..-3)) |> List.flatten() |> Enum.reverse()

    case opcode do
      1 ->
        op1 =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        op2 =
          if length(modes) > 1 and Enum.at(modes, 1) == "1",
            do: opcodes[i + 2],
            else: opcodes[opcodes[i + 2]]

        out = opcodes[i + 3]
        run_opcodes(Map.put(opcodes, out, op1 + op2), i + 4, input)

      2 ->
        op1 =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        op2 =
          if length(modes) > 1 and Enum.at(modes, 1) == "1",
            do: opcodes[i + 2],
            else: opcodes[opcodes[i + 2]]

        out = opcodes[i + 3]
        run_opcodes(Map.put(opcodes, out, op1 * op2), i + 4, input)

      3 ->
        out = opcodes[i + 1]
        run_opcodes(Map.put(opcodes, out, input), i + 2, input)

      4 ->
        if length(modes) > 0 and Enum.at(modes, 0) == "1",
          do: IO.puts(opcodes[i + 1]),
          else: IO.puts(opcodes[opcodes[i + 1]])

        run_opcodes(opcodes, i + 2, input)

      5 ->
        op1 =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        op2 =
          if length(modes) > 1 and Enum.at(modes, 1) == "1",
            do: opcodes[i + 2],
            else: opcodes[opcodes[i + 2]]

        run_opcodes(
          opcodes,
          if op1 != 0 do
            op2
          else
            i + 3
          end,
          input
        )

      6 ->
        op1 =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        op2 =
          if length(modes) > 1 and Enum.at(modes, 1) == "1",
            do: opcodes[i + 2],
            else: opcodes[opcodes[i + 2]]

        run_opcodes(
          opcodes,
          if op1 == 0 do
            op2
          else
            i + 3
          end,
          input
        )

      7 ->
        op1 =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        op2 =
          if length(modes) > 1 and Enum.at(modes, 1) == "1",
            do: opcodes[i + 2],
            else: opcodes[opcodes[i + 2]]

        out = opcodes[i + 3]

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
          input
        )

      8 ->
        op1 =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        op2 =
          if length(modes) > 1 and Enum.at(modes, 1) == "1",
            do: opcodes[i + 2],
            else: opcodes[opcodes[i + 2]]

        out = opcodes[i + 3]

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
          input
        )

      99 ->
        opcodes
    end
  end
end

opcodes =
  File.read!("day5.input")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.with_index(0)
  |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

case System.argv() do
  ["1"] ->
    opcodes
    |> Day5.run_opcodes(0, 1)

  ["2"] ->
    opcodes
    |> Day5.run_opcodes(0, 5)
end
