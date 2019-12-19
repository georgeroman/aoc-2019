defmodule Day18 do
  defp get_keys_reachable_from(from, paths, owned_keys, visited) do
    paths[from]
    |> Map.keys()
    |> Enum.filter(fn key ->
      key != from and
        not MapSet.member?(visited, key) and
        paths[from][key] |> elem(1) |> MapSet.difference(owned_keys) |> Enum.empty?()
    end)
  end

  # Try all possible valid paths that go through all keys, taking into account
  # the 4 robots that move in their associated vaults
  def dfs_vaults(robots, vault_paths, keys, visited, owned_keys, cache) do
    not_owned_keys = MapSet.difference(keys, owned_keys)

    if Map.has_key?(cache, {robots, not_owned_keys}) do
      {cache[{robots, not_owned_keys}], cache}
    else
      inf = 999_999

      {min_distance, cache} =
        robots
        |> Enum.with_index()
        |> Enum.reduce({inf, cache}, fn {current, idx}, {min_distance, cache} ->
          get_keys_reachable_from(current, vault_paths[idx], owned_keys, visited)
          |> Enum.reduce({min_distance, cache}, fn key, {min_distance, cache} ->
            {next_distance, next_cache} =
              dfs_vaults(
                List.replace_at(robots, idx, key),
                vault_paths,
                keys,
                MapSet.put(visited, current),
                MapSet.put(owned_keys, key),
                cache
              )

            {
              min(min_distance, (vault_paths[idx][current][key] |> elem(0)) + next_distance),
              next_cache
            }
          end)
        end)
        |> (fn {distance, cache} ->
              if distance == inf, do: {0, cache}, else: {distance, cache}
            end).()

      {min_distance, Map.put(cache, {robots, not_owned_keys}, min_distance)}
    end
  end

  # Try all possible valid paths that go through all keys
  # and get the minimum distance one
  def dfs(current, paths, keys, visited, owned_keys, cache) do
    not_owned_keys = MapSet.difference(keys, owned_keys)

    if Map.has_key?(cache, {current, not_owned_keys}) do
      {cache[{current, not_owned_keys}], cache}
    else
      inf = 999_999

      {min_distance, cache} =
        get_keys_reachable_from(current, paths, owned_keys, visited)
        |> Enum.reduce({inf, cache}, fn key, {min_distance, cache} ->
          {next_distance, next_cache} =
            dfs(
              key,
              paths,
              keys,
              MapSet.put(visited, current),
              MapSet.put(owned_keys, key),
              cache
            )

          {
            min(min_distance, (paths[current][key] |> elem(0)) + next_distance),
            next_cache
          }
        end)
        |> (fn {distance, cache} ->
              if distance == inf, do: {0, cache}, else: {distance, cache}
            end).()

      {min_distance, Map.put(cache, {current, not_owned_keys}, min_distance)}
    end
  end

  # Determine the distance and the doors that sit in between a
  # starting key (or start point '@') and all the other reachable keys
  def bfs(map, q, visited, paths) do
    {{:value, {{row, col}, steps, keys_in_path}}, q} = :queue.out(q)

    visited = MapSet.put(visited, {row, col})

    keys_in_path =
      if Map.get(map, {row, col}) =~ ~r/^[A-Z]$/,
        do: MapSet.put(keys_in_path, String.downcase(map[{row, col}])),
        else: keys_in_path

    paths =
      if Map.get(map, {row, col}) =~ ~r/^[a-z]$/,
        do: Map.put(paths, map[{row, col}], {steps, keys_in_path}),
        else: paths

    q =
      if Map.get(map, {row - 1, col}) != "#" and not MapSet.member?(visited, {row - 1, col}),
        do: :queue.in({{row - 1, col}, steps + 1, keys_in_path}, q),
        else: q

    q =
      if Map.get(map, {row + 1, col}) != "#" and not MapSet.member?(visited, {row + 1, col}),
        do: :queue.in({{row + 1, col}, steps + 1, keys_in_path}, q),
        else: q

    q =
      if Map.get(map, {row, col - 1}) != "#" and not MapSet.member?(visited, {row, col - 1}),
        do: :queue.in({{row, col - 1}, steps + 1, keys_in_path}, q),
        else: q

    q =
      if Map.get(map, {row, col + 1}) != "#" and not MapSet.member?(visited, {row, col + 1}),
        do: :queue.in({{row, col + 1}, steps + 1, keys_in_path}, q),
        else: q

    if :queue.is_empty(q), do: paths, else: bfs(map, q, visited, paths)
  end
end

map =
  Regex.scan(~r/[a-zA-Z.#@\n]/, File.read!("day18.input"))
  |> List.flatten()
  |> Enum.reduce({{0, 0}, %{}}, fn mark, {{row, col}, map} ->
    if mark == "\n" do
      {{row + 1, 0}, map}
    else
      {{row, col + 1}, Map.put(map, {row, col}, mark)}
    end
  end)
  |> elem(1)

case System.argv() do
  ["1"] ->
    keys =
      map
      |> Map.keys()
      |> Enum.filter(fn {row, col} -> map[{row, col}] =~ ~r/^[a-z@]$/ end)

    paths =
      for {row, col} <- keys,
          into: %{},
          do:
            {map[{row, col}],
             Day18.bfs(
               map,
               :queue.in({{row, col}, 0, MapSet.new()}, :queue.new()),
               MapSet.new(),
               %{}
             )}

    Day18.dfs(
      "@",
      paths,
      for({row, col} <- keys, into: MapSet.new(), do: map[{row, col}]),
      MapSet.new(),
      MapSet.new(),
      %{}
    )
    |> elem(0)
    |> IO.puts()

  ["2"] ->
    keys =
      map
      |> Map.keys()
      |> Enum.filter(fn {row, col} -> map[{row, col}] =~ ~r/^[a-z]$/ end)

    {row, col} =
      map
      |> Map.keys()
      |> Enum.find(fn {row, col} -> map[{row, col}] == "@" end)

    map = Map.put(map, {row, col}, "#")
    map = Map.put(map, {row - 1, col}, "#")
    map = Map.put(map, {row + 1, col}, "#")
    map = Map.put(map, {row, col - 1}, "#")
    map = Map.put(map, {row, col + 1}, "#")
    map = Map.put(map, {row - 1, col - 1}, "0")
    map = Map.put(map, {row - 1, col + 1}, "1")
    map = Map.put(map, {row + 1, col - 1}, "2")
    map = Map.put(map, {row + 1, col + 1}, "3")

    paths = fn start, keys ->
      for {row, col} <- [start | keys],
          into: %{},
          do:
            {map[{row, col}],
             Day18.bfs(
               map,
               :queue.in({{row, col}, 0, MapSet.new()}, :queue.new()),
               MapSet.new(),
               %{}
             )}
    end

    vault_paths = %{
      0 => paths.({row - 1, col - 1}, keys),
      1 => paths.({row - 1, col + 1}, keys),
      2 => paths.({row + 1, col - 1}, keys),
      3 => paths.({row + 1, col + 1}, keys)
    }

    robots = ["0", "1", "2", "3"]

    Day18.dfs_vaults(
      robots,
      vault_paths,
      for({row, col} <- keys, into: MapSet.new(), do: map[{row, col}]),
      MapSet.new(),
      MapSet.new(),
      %{}
    )
    |> elem(0)
    |> IO.puts()
end
