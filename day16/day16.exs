digits =
  Regex.scan(~r/./, File.read!("day16.input") |> String.trim())
  |> List.flatten()
  |> Enum.map(&String.to_integer/1)

calculate_rhs = fn len, idx ->
  Enum.at([0, 1, 0, -1], div(rem(idx + 1, 4 * len), len))
end

simulate = fn digits, steps ->
  Stream.iterate({digits, 0}, fn {digits, step} ->
    {
      1..length(digits)
      |> Enum.map(fn len ->
        digits
        |> Enum.with_index()
        |> Enum.reduce(0, fn {digit, idx}, acc ->
          acc + digit * calculate_rhs.(len, idx)
        end)
        |> (fn acc -> rem(abs(acc), 10) end).()
      end),
      step + 1
    }
  end)
  |> Enum.find(fn {_, step} -> step == steps end)
  |> elem(0)
end

simulate_ones_pattern = fn digits, steps ->
  Stream.iterate({digits, 0}, fn {digits, step} ->
    prefix_sums =
      digits
      |> Enum.with_index()
      |> Enum.reverse()
      |> Enum.reduce({0, %{}}, fn {digit, idx}, {sum, prefix_sums} ->
        sum = sum + digit
        {sum, Map.put(prefix_sums, idx, sum)}
      end)
      |> elem(1)

    {
      Enum.map(0..(length(digits) - 1), fn idx -> rem(prefix_sums[idx], 10) end),
      step + 1
    }
  end)
  |> Enum.find(fn {_, step} -> step == steps end)
  |> elem(0)
end

case System.argv() do
  ["1"] ->
    digits
    |> simulate.(100)
    |> Enum.take(8)
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join()
    |> IO.puts()

  ["2"] ->
    offset =
      digits
      |> Enum.take(7)
      |> Enum.drop_while(fn x -> x == 0 end)
      |> Enum.map(&Integer.to_string/1)
      |> Enum.join()
      |> String.to_integer()

    # For a big enough offset, the patterns starting from that point will look like
    # [0, 0, 0, ..., 1, 1, 1] so we only need to simulate the elements starting at that offset
    digits
    |> List.duplicate(10000)
    |> List.flatten()
    |> Enum.drop(offset)
    |> simulate_ones_pattern.(100)
    |> Enum.take(8)
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join()
    |> IO.puts()
end
