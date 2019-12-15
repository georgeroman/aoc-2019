defmodule Day13 do
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
end

opcodes =
  File.read!("day13.input")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.with_index(0)
  |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

get_joystick_tilt = fn tiles ->
  ball_x = tiles |> Enum.find(fn {_, id} -> id == 4 end)
  paddle_x = tiles |> Enum.find(fn {_, id} -> id == 3 end)

  if ball_x == nil or paddle_x == nil do
    nil
  else
    ball_x = ball_x |> elem(0) |> elem(0)
    paddle_x = paddle_x |> elem(0) |> elem(0)

    cond do
      ball_x - paddle_x == 0 -> 0
      ball_x - paddle_x < 0 -> -1
      ball_x - paddle_x > 0 -> 1
    end
  end
end

run_arcade = fn opcodes ->
  Stream.iterate({:ok, opcodes, 0, 0, 0, %{}}, fn {_, opcodes, last_index, base, highest_score,
                                                   tiles} ->
    {ok, opcodes, x, last_index, base} =
      Day13.run_opcodes(opcodes, last_index, base, get_joystick_tilt.(tiles))

    if ok == :halt do
      {ok, opcodes, last_index, base, highest_score, tiles}
    else
      {ok, opcodes, y, last_index, base} =
        Day13.run_opcodes(opcodes, last_index, base, get_joystick_tilt.(tiles))

      if ok == :halt do
        {ok, opcodes, last_index, base, highest_score, tiles}
      else
        if x == -1 and y == 0 do
          {ok, opcodes, score, last_index, base} =
            Day13.run_opcodes(opcodes, last_index, base, get_joystick_tilt.(tiles))

          {ok, opcodes, last_index, base, max(score, highest_score), tiles}
        else
          {ok, opcodes, id, last_index, base} =
            Day13.run_opcodes(opcodes, last_index, base, get_joystick_tilt.(tiles))

          {ok, opcodes, last_index, base, highest_score, Map.put(tiles, {x, y}, id)}
        end
      end
    end
  end)
  |> Enum.find(&(&1 |> elem(0) == :halt))
end

case System.argv() do
  ["1"] ->
    opcodes
    |> run_arcade.()
    |> elem(5)
    |> Map.values()
    |> Enum.filter(fn id -> id == 2 end)
    |> length
    |> IO.puts()

  ["2"] ->
    opcodes
    |> Map.put(0, 2)
    |> run_arcade.()
    |> elem(4)
    |> IO.puts()
end
