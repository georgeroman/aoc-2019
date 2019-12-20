defmodule Day20 do
  # Returns the other entry of a given portal
  defp get_other_entry(portal_to, label, entry) do
    entries = MapSet.to_list(portal_to[label])

    if length(entries) < 2 do
      entries |> List.first() |> elem(0)
    else
      [{entry_1, _}, {entry_2, _}] = MapSet.to_list(portal_to[label])

      if entry_1 == entry, do: entry_2, else: entry_1
    end
  end

  def is_label(x, not_in \\ []) do
    x != nil and x =~ ~r/^[A-Z]$/ and Enum.find(not_in, &(&1 == x)) == nil
  end

  # BFS on the maze taking into account the portals
  def bfs(map, portal_to, q, visited, {final_row, final_col}) do
    {{:value, {{row, col}, steps}}, q} = :queue.out(q)

    visited = MapSet.put(visited, {row, col})

    if {row, col} === {final_row, final_col} do
      steps
    else
      add_entry = fn q, label, entry ->
        if MapSet.member?(visited, entry) do
          q
        else
          cond do
            map[entry] == "." ->
              :queue.in({entry, steps + 1}, q)

            is_label(map[entry], ["A"]) ->
              :queue.in({get_other_entry(portal_to, label, {row, col}), steps + 1}, q)

            true ->
              q
          end
        end
      end

      q = add_entry.(q, map[{row - 2, col}] <> map[{row - 1, col}], {row - 1, col})
      q = add_entry.(q, map[{row + 1, col}] <> map[{row + 2, col}], {row + 1, col})
      q = add_entry.(q, map[{row, col - 2}] <> map[{row, col - 1}], {row, col - 1})
      q = add_entry.(q, map[{row, col + 1}] <> map[{row, col + 2}], {row, col + 1})

      bfs(map, portal_to, q, visited, {final_row, final_col})
    end
  end

  # Returns whether an entry of a portal is on the
  # inner edge or the outer edge of the maze
  defp get_where_for_entry(portal_to, label, entry) do
    entries = MapSet.to_list(portal_to[label])

    if length(entries) < 2 do
      entries |> List.first() |> elem(1)
    else
      [{entry_1, where_1}, {_, where_2}] = entries

      if entry_1 == entry, do: where_1, else: where_2
    end
  end

  # Checks whether a portal is open at a given level
  defp is_open(portal_to, label, {row, col}, level) do
    if level == 0 do
      label == "ZZ" or
        get_where_for_entry(portal_to, label, {row, col}) == "inner"
    else
      label != "AA" and label != "ZZ"
    end
  end

  defp get_new_level(portal_to, label, {row, col}, level) do
    if get_where_for_entry(portal_to, label, {row, col}) == "inner",
      do: level + 1,
      # Stop at level 0
      else: if(level > 0, do: level - 1, else: level)
  end

  defp get_near_label(map, {row, col}) do
    cond do
      is_label(map[{row - 1, col}]) -> map[{row - 2, col}] <> map[{row - 1, col}]
      is_label(map[{row + 1, col}]) -> map[{row + 1, col}] <> map[{row + 2, col}]
      is_label(map[{row, col - 1}]) -> map[{row, col - 2}] <> map[{row, col - 1}]
      is_label(map[{row, col + 1}]) -> map[{row, col + 1}] <> map[{row, col + 2}]
    end
  end

  # BFS on the maze taking into account portals and levels
  def bfs_recursive(map, portal_to, shortest_paths_from, q, visited, {final_row, final_col}) do
    {{:value, {{row, col}, distance, level}}, q} = :queue.out(q)

    visited = MapSet.put(visited, {row, col, level})

    if {row, col} === {final_row, final_col} and level == 0 do
      distance
    else
      q =
        Enum.reduce(shortest_paths_from[{row, col}], q, fn {{row, col}, shortest_distance}, q ->
          label = get_near_label(map, {row, col})

          if is_open(portal_to, label, {row, col}, level) and
               not MapSet.member?(visited, {row, col, level}) do
            :queue.in(
              {
                get_other_entry(portal_to, label, {row, col}),
                distance + shortest_distance + 1,
                get_new_level(portal_to, label, {row, col}, level)
              },
              q
            )
          else
            q
          end
        end)

      bfs_recursive(map, portal_to, shortest_paths_from, q, visited, {final_row, final_col})
    end
  end

  # BFS to get the shortest distance from a given point to
  # any reachable portal entry in the maze
  def distance_to_portals(map, q, visited, distance_to) do
    {{:value, {{row, col}, distance}}, q} = :queue.out(q)

    visited = MapSet.put(visited, {row, col})

    add_distance = fn distance_to, entry ->
      if is_label(map[entry]),
        do: Map.put(distance_to, {row, col}, distance),
        else: distance_to
    end

    distance_to = add_distance.(distance_to, {row - 1, col})
    distance_to = add_distance.(distance_to, {row + 1, col})
    distance_to = add_distance.(distance_to, {row, col - 1})
    distance_to = add_distance.(distance_to, {row, col + 1})

    add_entry = fn q, entry ->
      if map[entry] == "." and not MapSet.member?(visited, entry),
        do: :queue.in({entry, distance + 1}, q),
        else: q
    end

    q = add_entry.(q, {row - 1, col})
    q = add_entry.(q, {row + 1, col})
    q = add_entry.(q, {row, col - 1})
    q = add_entry.(q, {row, col + 1})

    if :queue.is_empty(q),
      do: distance_to,
      else: distance_to_portals(map, q, visited, distance_to)
  end
end

map =
  Regex.scan(~r/[A-Z.# \n]/, File.read!("day20.input"))
  |> List.flatten()
  |> Enum.reduce({{0, 0}, %{}}, fn curr, {{row, col}, map} ->
    cond do
      curr == "." or curr == "#" or curr == " " or Day20.is_label(curr) ->
        {{row, col + 1}, Map.put(map, {row, col}, curr)}

      curr == "\n" ->
        {{row + 1, 0}, map}
    end
  end)
  |> elem(1)

portal_to =
  map
  |> Map.keys()
  |> Enum.filter(&Day20.is_label(map[&1]))
  |> Enum.reduce(%{}, fn {row, col}, portal_to ->
    {label, entry, where} =
      cond do
        Day20.is_label(map[{row - 1, col}]) ->
          {
            map[{row - 1, col}] <> map[{row, col}],
            if(map[{row + 1, col}] == ".", do: {row + 1, col}, else: {row - 2, col}),
            if(map[{row - 2, col}] == nil or map[{row + 1, col}] == nil,
              do: "outer",
              else: "inner"
            )
          }

        Day20.is_label(map[{row + 1, col}]) ->
          {
            map[{row, col}] <> map[{row + 1, col}],
            if(map[{row - 1, col}] == ".", do: {row - 1, col}, else: {row + 2, col}),
            if(map[{row - 1, col}] == nil or map[{row + 2, col}] == nil,
              do: "outer",
              else: "inner"
            )
          }

        Day20.is_label(map[{row, col - 1}]) ->
          {
            map[{row, col - 1}] <> map[{row, col}],
            if(map[{row, col + 1}] == ".", do: {row, col + 1}, else: {row, col - 2}),
            if(map[{row, col - 2}] == nil or map[{row, col + 1}] == nil,
              do: "outer",
              else: "inner"
            )
          }

        Day20.is_label(map[{row, col + 1}]) ->
          {
            map[{row, col}] <> map[{row, col + 1}],
            if(map[{row, col - 1}] == ".", do: {row, col - 1}, else: {row, col + 2}),
            if(map[{row, col - 1}] == nil or map[{row, col + 2}] == nil,
              do: "outer",
              else: "inner"
            )
          }
      end

    Map.put(portal_to, label, MapSet.put(Map.get(portal_to, label, MapSet.new()), {entry, where}))
  end)

{{start_row, start_col}, _} =
  portal_to["AA"]
  |> MapSet.to_list()
  |> List.first()

{{final_row, final_col}, _} =
  portal_to["ZZ"]
  |> MapSet.to_list()
  |> List.first()

case System.argv() do
  ["1"] ->
    Day20.bfs(
      map,
      portal_to,
      :queue.in({{start_row, start_col}, 0}, :queue.new()),
      MapSet.new(),
      {final_row, final_col}
    )
    |> IO.puts()

  ["2"] ->
    shortest_paths_from =
      portal_to
      |> Map.keys()
      |> Enum.reduce(%{}, fn label, shortest_paths_from ->
        Map.merge(
          shortest_paths_from,
          portal_to[label]
          |> MapSet.to_list()
          |> Enum.reduce(%{}, fn {{row, col}, _}, distance_to ->
            Map.put(
              distance_to,
              {row, col},
              Day20.distance_to_portals(
                map,
                :queue.in({{row, col}, 0}, :queue.new()),
                MapSet.new(),
                %{}
              )
              |> Map.delete({row, col})
            )
          end)
        )
      end)

    Day20.bfs_recursive(
      map,
      portal_to,
      shortest_paths_from,
      :queue.in({{start_row, start_col}, 0, 0}, :queue.new()),
      MapSet.new(),
      {final_row, final_col}
    )
    |> (fn x -> x - 1 end).()
    |> IO.puts()
end
