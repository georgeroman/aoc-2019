defmodule Day7 do
  def run_opcodes(opcodes, i, inputs) do
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
        run_opcodes(Map.put(opcodes, out, op1 + op2), i + 4, inputs)

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
        run_opcodes(Map.put(opcodes, out, op1 * op2), i + 4, inputs)

      3 ->
        out = opcodes[i + 1]
        run_opcodes(Map.put(opcodes, out, List.first(inputs)), i + 2, Enum.drop(inputs, 1))

      4 ->
        output =
          if length(modes) > 0 and Enum.at(modes, 0) == "1",
            do: opcodes[i + 1],
            else: opcodes[opcodes[i + 1]]

        {:ok, output, i + 2}

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
          inputs
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
          inputs
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
          inputs
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
          inputs
        )

      99 ->
        {:halt, nil, -1}
    end
  end

  def run_all_configs(opcodes, phase_settings, prev_max, feedback \\ false) do
    if length(phase_settings) == 5 do
      if feedback do
        max(
          prev_max,
          Stream.iterate({:ok, 0, %{}, %{}}, fn {_, input, last_indices, setting_input_consumed} ->
            Enum.reduce(
              phase_settings,
              {:ok, input, last_indices, setting_input_consumed},
              fn setting, {result, input, last_indices, setting_input_consumed} ->
                {new_result, output, last_index} =
                  run_opcodes(
                    opcodes,
                    Map.get(last_indices, setting, 0),
                    if not Map.has_key?(setting_input_consumed, setting) do
                      [setting, input]
                    else
                      [input]
                    end
                  )

                {
                  if(result == :halt, do: :halt, else: new_result),
                  output,
                  Map.put(last_indices, setting, last_index),
                  Map.put(setting_input_consumed, setting, true)
                }
              end
            )
          end)
          |> Enum.take_while(fn {result, _, _, _} -> result != :halt end)
          |> Enum.max()
          |> elem(1)
        )
      else
        max(
          prev_max,
          Enum.reduce(phase_settings, 0, fn setting, input ->
            run_opcodes(opcodes, 0, [setting, input]) |> elem(1)
          end)
        )
      end
    else
      Enum.max(
        for setting <- if(feedback, do: 5..9, else: 0..4) do
          if not Enum.member?(phase_settings, setting) do
            run_all_configs(opcodes, phase_settings ++ [setting], prev_max, feedback)
          else
            prev_max
          end
        end
      )
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
    |> Day7.run_all_configs([], 0)
    |> IO.puts()

  ["2"] ->
    opcodes
    |> Day7.run_all_configs([], 0, true)
    |> IO.puts()
end
