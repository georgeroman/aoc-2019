defmodule Day12 do
  def gcd(a, 0), do: a
  def gcd(0, b), do: b
  def gcd(a, b), do: gcd(b, rem(a, b))

  def lcm(0, 0), do: 0
  def lcm(a, b), do: div(a * b, gcd(a, b))
end

moons =
  File.stream!("day12.input")
  |> Enum.with_index()
  |> Enum.map(fn {data, i} ->
    s_position = Regex.named_captures(~r/x=(?<x>[-\d]+), y=(?<y>[-\d]+), z=(?<z>[-\d]+)/, data)
    pos = for {k, v} <- s_position, into: %{}, do: {:"#{k}", String.to_integer(v)}
    vel = for k <- [:x, :y, :z], into: %{}, do: {k, 0}
    {:"#{i}", %{pos: pos, vel: vel}}
  end)

update_velocity = fn moons, i, j, coord ->
  {i, j} = {:"#{i}", :"#{j}"}

  pos_i = moons[i][:pos][coord]
  pos_j = moons[j][:pos][coord]

  if pos_i < pos_j do
    moons = put_in(moons, [i, :vel, coord], moons[i][:vel][coord] + 1)
    put_in(moons, [j, :vel, coord], moons[j][:vel][coord] - 1)
  else
    if pos_j < pos_i do
      moons = put_in(moons, [j, :vel, coord], moons[j][:vel][coord] + 1)
      put_in(moons, [i, :vel, coord], moons[i][:vel][coord] - 1)
    else
      moons
    end
  end
end

update_position = fn moons, i, coord ->
  i = :"#{i}"
  put_in(moons, [i, :pos, coord], moons[i][:pos][coord] + moons[i][:vel][coord])
end

simulate = fn moons, steps ->
  Stream.iterate(moons, fn moons ->
    Enum.reduce(0..3, moons, fn i, moons ->
      Enum.reduce(
        [:x, :y, :z],
        Enum.reduce(0..3, moons, fn j, moons ->
          if i < j do
            Enum.reduce([:x, :y, :z], moons, fn coord, moons ->
              update_velocity.(moons, i, j, coord)
            end)
          else
            moons
          end
        end),
        fn coord, moons -> update_position.(moons, i, coord) end
      )
    end)
  end)
  |> Enum.at(steps)
end

equal = fn l1, l2 ->
  Enum.all?(Enum.zip(l1, l2), fn {x, y} -> x == y end)
end

find_cycle = fn pos, vel ->
  {first_pos, first_vel} = {pos, vel}

  Stream.iterate({pos, vel}, fn {pos, vel} ->
    vel =
      Enum.reduce(0..3, vel, fn i, vel ->
        add =
          Enum.reduce(0..3, 0, fn j, add ->
            if Enum.at(pos, i) < Enum.at(pos, j) do
              add + 1
            else
              if Enum.at(pos, j) < Enum.at(pos, i) do
                add - 1
              else
                add
              end
            end
          end)

        List.replace_at(vel, i, Enum.at(vel, i) + add)
      end)

    {Enum.with_index(pos) |> Enum.map(fn {p, i} -> p + Enum.at(vel, i) end), vel}
  end)
  |> Stream.drop(1)
  |> Enum.find_index(fn {pos, vel} -> equal.(pos, first_pos) and equal.(vel, first_vel) end)
  |> (fn x -> x + 1 end).()
end

case System.argv() do
  ["1"] ->
    simulation = moons |> simulate.(1000)

    IO.puts(
      Enum.sum(
        for i <- 0..3 do
          i = :"#{i}"

          Enum.sum(Map.values(simulation[i][:pos]) |> Enum.map(&abs/1)) *
            Enum.sum(Map.values(simulation[i][:vel]) |> Enum.map(&abs/1))
        end
      )
    )

  ["2"] ->
    separate_by = fn by ->
      Enum.reduce([:x, :y, :z], %{}, fn coord, pos ->
        Map.put(pos, coord, for(i <- 0..3, into: [], do: moons[:"#{i}"][by][coord]))
      end)
    end

    pos = separate_by.(:pos)
    vel = separate_by.(:vel)

    [cycle_x, cycle_y, cycle_z] =
      for coord <- [:x, :y, :z] do
        pos_coord = pos[coord]
        vel_coord = vel[coord]
        find_cycle.(pos_coord, vel_coord)
      end

    IO.puts(Day12.lcm(cycle_x, Day12.lcm(cycle_y, cycle_z)))
end
