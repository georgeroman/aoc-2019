defmodule Day11 do
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

  def run_opcodes(opcodes, i, base, input) do
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
end

opcodes =
  File.read!("day11.input")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.with_index(0)
  |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

paint = fn start_color ->
  Stream.iterate({:ok, opcodes, 0, 0, Map.put(%{}, {0, 0}, start_color), "up", {0, 0}}, fn {_,
                                                                                            opcodes,
                                                                                            last_index,
                                                                                            base,
                                                                                            colors,
                                                                                            facing,
                                                                                            {x, y}} ->
    current_color = Map.get(colors, {x, y}, 0)

    {ok, opcodes, color, last_index, base} =
      Day11.run_opcodes(opcodes, last_index, base, current_color)

    if ok == :halt do
      {ok, opcodes, last_index, base, colors, facing, {x, y}}
    else
      {ok, opcodes, direction, last_index, base} =
        Day11.run_opcodes(opcodes, last_index, base, color)

      {facing, {new_x, new_y}} =
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

      {ok, opcodes, last_index, base, Map.put(colors, {x, y}, color), facing, {new_x, new_y}}
    end
  end)
  |> Enum.find(&(&1 |> elem(0) == :halt))
end

case System.argv() do
  ["1"] ->
    paint.(0)
    |> elem(4)
    |> map_size
    |> IO.inspect()

  ["2"] ->
    colors = paint.(1) |> elem(4)
    white_colored = Enum.filter(Map.keys(colors), fn {x, y} -> colors[{x, y}] == 1 end)

    x_sorted = Enum.sort(white_colored, fn {x1, _}, {x2, _} -> x1 < x2 end)
    {min_x, max_x} = {List.first(x_sorted) |> elem(0), List.last(x_sorted) |> elem(0)}

    y_sorted = Enum.sort(white_colored, fn {_, y1}, {_, y2} -> y1 < y2 end)
    {min_y, max_y} = {List.first(y_sorted) |> elem(1), List.last(y_sorted) |> elem(1)}

    IO.puts(
      Enum.join(
        for y <- min_y..max_y do
          Enum.join(
            Enum.map(
              for x <- min_x..max_x do
                colors[{x, y}]
              end,
              fn color -> if color == 0, do: " ", else: "#" end
            ),
            " "
          )
        end,
        "\n"
      )
    )
end
