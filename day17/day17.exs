defmodule Day17 do
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

generate_map = fn opcodes ->
  Stream.iterate({:ok, opcodes, 0, 0, {0, 0}, %{}}, fn {_, opcodes, last_index, base, {row, col},
                                                        map} ->
    {result, opcodes, output, _, last_index, base} = Day17.run_opcodes(opcodes, last_index, base)

    map = if result == :ok, do: Map.put(map, {row, col}, List.to_string([output])), else: map

    {row, col} =
      case output do
        10 -> {row + 1, 0}
        _ -> {row, col + 1}
      end

    {result, opcodes, last_index, base, {row, col}, map}
  end)
  |> Enum.find(fn {result, _, _, _, _, _} -> result == :halt end)
  |> elem(5)
end

get_intersections = fn map ->
  map
  |> Map.keys()
  |> Enum.reduce([], fn {row, col}, intersections ->
    middle = Map.get(map, {row, col})
    up = Map.get(map, {row - 1, col})
    down = Map.get(map, {row + 1, col})
    left = Map.get(map, {row, col - 1})
    right = Map.get(map, {row, col + 1})

    if middle == "#" and up == "#" and down == "#" and left == "#" and right == "#" do
      [{row, col} | intersections]
    else
      intersections
    end
  end)
end

get_path = fn map ->
  {row, col} =
    Enum.find(map, fn {_, val} -> val == "^" or val == "<" or val == "v" or val == ">" end)
    |> elem(0)

  Stream.iterate({:continue, "up", {row, col}, []}, fn {_, prev_direction, {row, col}, moves} ->
    {next_direction, rotation} =
      if prev_direction == "up" or prev_direction == "down" do
        cond do
          map[{row, col - 1}] == "#" -> {"left", if(prev_direction == "up", do: "L", else: "R")}
          map[{row, col + 1}] == "#" -> {"right", if(prev_direction == "up", do: "R", else: "L")}
          true -> {nil, nil}
        end
      else
        cond do
          map[{row - 1, col}] == "#" ->
            {"up", if(prev_direction == "right", do: "L", else: "R")}

          map[{row + 1, col}] == "#" ->
            {"down", if(prev_direction == "right", do: "R", else: "L")}

          true ->
            {nil, nil}
        end
      end

    if next_direction == nil do
      {:halt, nil, nil, moves}
    else
      {row_increment, col_increment} =
        case next_direction do
          "up" -> {-1, 0}
          "down" -> {1, 0}
          "left" -> {0, -1}
          "right" -> {0, 1}
        end

      path =
        Stream.iterate({row, col}, fn {row, col} ->
          {row + row_increment, col + col_increment}
        end)
        |> Stream.drop(1)
        |> Enum.take_while(fn {row, col} -> Map.get(map, {row, col}, ".") == "#" end)

      {:continue, next_direction, List.last(path), [{rotation, length(path)} | moves]}
    end
  end)
  |> Enum.find(fn {status, _, _, _} -> status == :halt end)
  |> elem(3)
  |> Enum.reverse()
end

get_movement_functions = fn moves ->
  {min_size, max_size} = {2, 6}

  possible_lengths =
    for size_a <- min_size..max_size,
        size_b <- min_size..max_size,
        size_c <- min_size..max_size,
        into: [],
        do: [size_a, size_b, size_c]

  # Get the sublist consisting of the first len elements in the list
  # and drop all occurences of this sublist from the rest of the list
  take_and_drop_sublist = fn moves, len ->
    sublist = Enum.take(moves, len)

    0..(length(moves) - 1)
    |> Enum.map(fn idx ->
      tmp = Enum.slice(moves, idx..(idx + len - 1))
      if match?(^tmp, sublist), do: true, else: false
    end)
    |> Enum.with_index()
    |> Enum.reduce({nil, []}, fn {is_sublist_instance, idx}, {prev_idx, list} ->
      prev_idx = if is_sublist_instance, do: idx, else: prev_idx

      list =
        if prev_idx == nil or idx - prev_idx < len, do: list, else: [Enum.at(moves, idx) | list]

      {prev_idx, list}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  # Generate possible settings
  matches =
    Enum.map(possible_lengths, fn [length_a, length_b, length_c] ->
      tmp_moves = moves
      a = Enum.take(tmp_moves, length_a)
      tmp_moves = take_and_drop_sublist.(tmp_moves, length_a)
      b = Enum.take(tmp_moves, length_b)
      tmp_moves = take_and_drop_sublist.(tmp_moves, length_b)
      c = Enum.take(tmp_moves, length_c)

      # Try to match the previous movement functions on the list of moves
      match_result =
        Stream.iterate({:searching, moves, []}, fn {_, moves, order} ->
          if Enum.empty?(moves) do
            {:match, nil, order}
          else
            tmp = Enum.take(moves, length_a)
            match_a = match?(^tmp, a)
            tmp = Enum.take(moves, length_b)
            match_b = match?(^tmp, b)
            tmp = Enum.take(moves, length_c)
            match_c = match?(^tmp, c)

            case {match_a, match_b, match_c} do
              {true, _, _} -> {:searching, Enum.drop(moves, length_a), ["A" | order]}
              {_, true, _} -> {:searching, Enum.drop(moves, length_b), ["B" | order]}
              {_, _, true} -> {:searching, Enum.drop(moves, length_c), ["C" | order]}
              _ -> {:no_match, nil, nil}
            end
          end
        end)
        |> Enum.find(fn {status, _, _} -> status == :no_match or status == :match end)

      if match_result |> elem(0) == :match do
        {true, match_result |> elem(2), a, b, c}
      else
        {false, nil, nil, nil, nil}
      end
    end)

  # Assume a valid setting is always available
  {_, main, a, b, c} = Enum.find(matches, fn {is_valid, _, _, _, _} -> is_valid == true end)
  {Enum.reverse(main), a, b, c}
end

opcodes =
  File.read!("day17.input")
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(&String.to_integer/1)
  |> Enum.with_index(0)
  |> Enum.reduce(%{}, fn {op, i}, acc -> Map.put(acc, i, op) end)

case System.argv() do
  ["1"] ->
    opcodes
    |> generate_map.()
    |> get_intersections.()
    |> Enum.map(fn {row, col} -> row * col end)
    |> Enum.sum()
    |> IO.puts()

  ["2"] ->
    {main, a, b, c} =
      opcodes
      |> generate_map.()
      |> get_path.()
      |> get_movement_functions.()

    add_newline = fn x -> x <> "\n" end

    movement_list_to_charlist = fn movements ->
      movements
      |> Enum.map(fn {direction, steps} -> direction <> "," <> Integer.to_string(steps) end)
      |> Enum.join(",")
      |> add_newline.()
      |> String.to_charlist()
    end

    main_input =
      main
      |> Enum.join(",")
      |> add_newline.()
      |> String.to_charlist()

    a_input = movement_list_to_charlist.(a)
    b_input = movement_list_to_charlist.(b)
    c_input = movement_list_to_charlist.(c)
    video_input = String.to_charlist("n\n")

    input = main_input ++ a_input ++ b_input ++ c_input ++ video_input

    Stream.iterate({:ok, Map.put(opcodes, 0, 2), nil, input, 0, 0}, fn {_, opcodes, _, input,
                                                                        last_index, base} ->
      Day17.run_opcodes(opcodes, last_index, base, input)
    end)
    |> Enum.take_while(fn {status, _, _, _, _, _} -> status != :halt end)
    |> List.last()
    |> elem(2)
    |> IO.puts()
end
