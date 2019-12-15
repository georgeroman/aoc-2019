defmodule Day10 do
  def are_collinear({x1, y1}, {x2, y2}, {x3, y3}) do
    x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2) == 0
  end

  def detectable_from(asteroids, {x1, y1}) do
    {order, detectable, _} =
      Enum.reduce(asteroids, {%{}, MapSet.new(), MapSet.put(MapSet.new(), {x1, y1})}, fn {x2, y2},
                                                                                         {order,
                                                                                          detectable,
                                                                                          non_detectable} ->
        if MapSet.member?(non_detectable, {x2, y2}) do
          {order, detectable, non_detectable}
        else
          {
            Map.put(order, map_size(order) + 1, {x2, y2}),
            MapSet.put(detectable, {x2, y2}),
            Enum.reduce(asteroids, MapSet.put(non_detectable, {x2, y2}), fn {x3, y3},
                                                                            non_detectable ->
              if are_collinear({x1, y1}, {x2, y2}, {x3, y3}) and
                   {x3 - x1 > 0, y3 - y1 > 0} == {x2 - x1 > 0, y2 - y1 > 0} do
                MapSet.put(non_detectable, {x3, y3})
              else
                non_detectable
              end
            end)
          }
        end
      end)

    {order, detectable}
  end
end

width = 28

asteroids =
  Regex.scan(~r/./, File.read!("day10.input"))
  |> List.flatten()
  |> Enum.with_index()
  |> Enum.reduce([], fn {curr, i}, asteroids ->
    if curr == "#", do: [{rem(i, width), div(i, width)} | asteroids], else: asteroids
  end)
  |> Enum.sort()

case System.argv() do
  ["1"] ->
    asteroids
    |> Enum.reduce({0, {-1, -1}}, fn {x1, y1}, {max_count, coords} ->
      # Sort the points by the Manhattan distance from the center
      asteroids =
        Enum.sort(asteroids, fn {x2, y2}, {x3, y3} ->
          abs(x1 - x2) + abs(y1 - y2) < abs(x1 - x3) + abs(y1 - y3)
        end)

      max(
        {max_count, coords},
        {Day10.detectable_from(asteroids, {x1, y1}) |> elem(1) |> MapSet.size(), {x1, y1}}
      )
    end)
    |> IO.inspect()

  ["2"] ->
    {x1, y1} = {22, 19}

    # Sort the points clockwise by the angle they form with the vertical axis
    asteroids =
      Enum.sort(asteroids, fn {x2, y2}, {x3, y3} ->
        vertical = :math.atan2(y1, 0) * 180 / :math.pi()
        angle2 = vertical - :math.atan2(y1 - y2, x2 - x1) * 180 / :math.pi()
        angle3 = vertical - :math.atan2(y1 - y3, x3 - x1) * 180 / :math.pi()

        angle2 = if angle2 < 0, do: angle2 + 360, else: angle2
        angle3 = if angle3 < 0, do: angle3 + 360, else: angle3

        angle2 < angle3
      end)

    Day10.detectable_from(asteroids, {x1, y1})
    |> elem(0)
    |> (fn order -> order[200] end).()
    |> (fn {x, y} -> x * 100 + y end).()
    |> IO.inspect()
end
