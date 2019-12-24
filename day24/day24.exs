grid =
  Regex.scan(~r/[.#\n]/, File.read!("day24.input"))
  |> List.flatten()
  |> Enum.reduce({%{}, 0, 0}, fn tile, {grid, row, col} ->
    cond do
      tile == "\n" ->
        {grid, row + 1, 0}

      true ->
        {Map.put(grid, {row, col}, tile), row, col + 1}
    end
  end)
  |> elem(0)

simulate = fn ->
  Stream.iterate(grid, fn grid ->
    Enum.reduce(grid, %{}, fn {{row, col}, tile}, new_grid ->
      num_adjacent =
        Enum.count(
          [
            grid[{row - 1, col}] == "#",
            grid[{row + 1, col}] == "#",
            grid[{row, col - 1}] == "#",
            grid[{row, col + 1}] == "#"
          ],
          & &1
        )

      if tile == "#" do
        if num_adjacent != 1,
          do: Map.put(new_grid, {row, col}, "."),
          else: Map.put(new_grid, {row, col}, "#")
      else
        if num_adjacent == 1 or num_adjacent == 2,
          do: Map.put(new_grid, {row, col}, "#"),
          else: Map.put(new_grid, {row, col}, ".")
      end
    end)
  end)
end

simulate_recursive = fn ->
  {%{0 => grid}, 0}
  |> Stream.iterate(fn {grids, minutes} ->
    empty_grid = for row <- 0..4, col <- 0..4, into: %{}, do: {{row, col}, "."}

    grids = Map.put(grids, minutes + 1, empty_grid)
    grids = Map.put(grids, -minutes - 1, empty_grid)

    grids =
      Enum.reduce(grids, %{}, fn {level, grid}, new_grids ->
        Map.put(
          new_grids,
          level,
          Enum.reduce(grid, %{}, fn {{row, col}, tile}, new_grid ->
            if {row, col} == {2, 2} do
              Map.put(new_grid, {row, col}, ".")
            else
              num_adjacent_up =
                if {row - 1, col} == {2, 2} do
                  if grids[level + 1] == nil do
                    0
                  else
                    for(col <- 0..4, do: grids[level + 1][{4, col}] == "#")
                    |> Enum.count(& &1)
                  end
                else
                  case row - 1 < 0 do
                    true ->
                      if grids[level - 1] == nil,
                        do: 0,
                        else: if(grids[level - 1][{1, 2}] == "#", do: 1, else: 0)

                    false ->
                      if grid[{row - 1, col}] == "#", do: 1, else: 0
                  end
                end

              num_adjacent_down =
                if {row + 1, col} == {2, 2} do
                  if grids[level + 1] == nil do
                    0
                  else
                    for(col <- 0..4, do: grids[level + 1][{0, col}] == "#")
                    |> Enum.count(& &1)
                  end
                else
                  case row + 1 > 4 do
                    true ->
                      if grids[level - 1] == nil,
                        do: 0,
                        else: if(grids[level - 1][{3, 2}] == "#", do: 1, else: 0)

                    false ->
                      if grid[{row + 1, col}] == "#", do: 1, else: 0
                  end
                end

              num_adjacent_left =
                if {row, col - 1} == {2, 2} do
                  if grids[level + 1] == nil do
                    0
                  else
                    for(row <- 0..4, do: grids[level + 1][{row, 4}] == "#")
                    |> Enum.count(& &1)
                  end
                else
                  case col - 1 < 0 do
                    true ->
                      if grids[level - 1] == nil,
                        do: 0,
                        else: if(grids[level - 1][{2, 1}] == "#", do: 1, else: 0)

                    false ->
                      if grid[{row, col - 1}] == "#", do: 1, else: 0
                  end
                end

              num_adjacent_right =
                if {row, col + 1} == {2, 2} do
                  if grids[level + 1] == nil do
                    0
                  else
                    for(row <- 0..4, do: grids[level + 1][{row, 0}] == "#")
                    |> Enum.count(& &1)
                  end
                else
                  case col + 1 > 4 do
                    true ->
                      if grids[level - 1] == nil,
                        do: 0,
                        else: if(grids[level - 1][{2, 3}] == "#", do: 1, else: 0)

                    false ->
                      if grid[{row, col + 1}] == "#", do: 1, else: 0
                  end
                end

              num_adjacent =
                num_adjacent_up + num_adjacent_down + num_adjacent_left + num_adjacent_right

              if tile == "#" do
                if num_adjacent != 1,
                  do: Map.put(new_grid, {row, col}, "."),
                  else: Map.put(new_grid, {row, col}, "#")
              else
                if num_adjacent == 1 or num_adjacent == 2,
                  do: Map.put(new_grid, {row, col}, "#"),
                  else: Map.put(new_grid, {row, col}, ".")
              end
            end
          end)
        )
      end)

    {grids, minutes + 1}
  end)
end

case System.argv() do
  ["1"] ->
    [layout] =
      simulate.()
      |> Stream.transform({MapSet.new(), false}, fn grid, {prev_grids, found} ->
        if found do
          {:halt, found}
        else
          if MapSet.member?(prev_grids, grid) do
            {[grid], {prev_grids, true}}
          else
            {[], {MapSet.put(prev_grids, grid), false}}
          end
        end
      end)
      |> Enum.to_list()

    for row <- 0..4, col <- 0..4 do
      if layout[{row, col}] == "#" do
        :math.pow(2, row * 5 + col) |> round()
      else
        0
      end
    end
    |> Enum.sum()
    |> IO.puts()

  ["2"] ->
    simulate_recursive.()
    |> Enum.find(fn {_, minutes} -> minutes == 200 end)
    |> elem(0)
    |> Enum.map(fn {_, grid} ->
      for row <- 0..4, col <- 0..4 do
        if grid[{row, col}] == "#", do: 1, else: 0
      end
      |> Enum.sum()
    end)
    |> Enum.sum()
    |> IO.puts()
end
