defmodule Day19 do
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
        run_opcodes(Map.put(opcodes, out, List.first(input)), i + 2, base, Enum.drop(input, 1))

      4 ->
        output = select_mode_in(opcodes, modes, base, i + 1, 0)
        {:ok, opcodes, output, input, i + 2, base}

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
        {:halt, nil, nil, nil, -1, -1}
    end
  end
end

opcodes =
  File.read!("day19.input")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.with_index(0)
  |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

case System.argv() do
  ["1"] ->
    Enum.count(
      for y <- 0..49, x <- 0..49 do
        Day19.run_opcodes(opcodes, 0, 0, [x, y]) |> elem(2) == 1
      end,
      fn is_affected -> is_affected end
    )
    |> IO.puts()

  ["2"] ->
    initial_search_range = 0..5

    {start_x, start_y} =
      Enum.find(for(y <- initial_search_range, x <- initial_search_range, do: {x, y}), fn {x, y} ->
        Day19.run_opcodes(opcodes, 0, 0, [x, y]) |> elem(2) == 1 and
          Day19.run_opcodes(opcodes, 0, 0, [x + 1, y + 1]) |> elem(2) == 1
      end)

    Stream.iterate({MapSet.new(), start_x, start_x, start_y}, fn {prev_points, min_x, max_x, y} ->
      next_min_x =
        Stream.iterate(min_x, fn x -> x + 1 end)
        |> Enum.find(fn x -> Day19.run_opcodes(opcodes, 0, 0, [x, y + 1]) |> elem(2) == 1 end)

      next_max_x =
        Stream.iterate(max(next_min_x, max_x), fn x -> x + 1 end)
        |> Enum.take_while(fn x ->
          Day19.run_opcodes(opcodes, 0, 0, [x, y + 1]) |> elem(2) == 1
        end)
        |> List.last()

      {MapSet.put(prev_points, {max_x, y}), next_min_x, next_max_x, y + 1}
    end)
    |> Enum.find(fn {prev_points, min_x, _, y} ->
      MapSet.member?(prev_points, {min_x + 99, y - 99})
    end)
    |> (fn {_, min_x, _, y} -> min_x * 10000 + y - 99 end).()
    |> IO.puts()
end
