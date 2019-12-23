defmodule Day23 do
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
        if input == nil do
          {:input, opcodes, i, base, nil}
        else
          out = select_mode_out(opcodes, modes, base, i + 1, 0)
          run_opcodes(Map.put(opcodes, out, input), i + 2, base, nil)
        end

      4 ->
        output = select_mode_in(opcodes, modes, base, i + 1, 0)
        {:output, opcodes, i + 2, base, output}

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
        {:halt, nil, nil, nil, nil}
    end
  end
end

opcodes =
  File.read!("day23.input")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.with_index(0)
  |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

run_simulation = fn ->
  computers =
    for address <- 0..49,
        into: %{},
        do: {address, Day23.run_opcodes(opcodes, 0, 0, address)}

  Stream.iterate({computers, %{}, []}, fn {computers, inbox, sent_from_255} ->
    {computers, inbox} =
      Enum.reduce(computers, {computers, inbox}, fn {address,
                                                     {status, opcodes, last_index, base,
                                                      destination}},
                                                    {computers, inbox} ->
        case status do
          :output ->
            {_, opcodes, last_index, base, x} = Day23.run_opcodes(opcodes, last_index, base)
            {_, opcodes, last_index, base, y} = Day23.run_opcodes(opcodes, last_index, base)

            {
              Map.put(computers, address, Day23.run_opcodes(opcodes, last_index, base)),
              Map.put(inbox, destination, Map.get(inbox, destination, []) ++ [{x, y}])
            }

          :input ->
            if length(Map.get(inbox, address, [])) == 0 do
              {
                Map.put(computers, address, Day23.run_opcodes(opcodes, last_index, base, -1)),
                inbox
              }
            else
              {x, y} = List.first(inbox[address])

              {_, opcodes, last_index, base, _} = Day23.run_opcodes(opcodes, last_index, base, x)

              {
                Map.put(computers, address, Day23.run_opcodes(opcodes, last_index, base, y)),
                Map.put(inbox, address, Enum.drop(inbox[address], 1))
              }
            end
        end
      end)

    is_idle =
      Enum.map(computers, fn {address, {status, _, _, _, _}} ->
        status == :input and Map.get(inbox, address, []) |> Enum.empty?()
      end)
      |> Enum.all?(& &1)

    if is_idle and length(Map.get(inbox, 255, [])) > 0 do
      {
        computers,
        Map.put(inbox, 0, [List.last(inbox[255])]),
        [List.last(inbox[255]) | sent_from_255]
      }
    else
      {computers, inbox, sent_from_255}
    end
  end)
end

case System.argv() do
  ["1"] ->
    run_simulation.()
    |> Enum.find(fn {_, inbox, _} -> Map.has_key?(inbox, 255) end)
    |> elem(1)
    |> Map.get(255)
    |> List.first()
    |> elem(1)
    |> IO.puts()

  ["2"] ->
    run_simulation.()
    |> Enum.find(fn {_, _, sent_from_255} ->
      length(sent_from_255) >= 2 and
        Enum.at(sent_from_255, 0) |> elem(1) == Enum.at(sent_from_255, 1) |> elem(1)
    end)
    |> elem(2)
    |> (fn sent_from_255 -> List.first(sent_from_255) |> elem(1) end).()
    |> IO.puts()
end
