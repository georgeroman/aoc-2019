[low, high] =
  File.read!("day4.input")
    |> String.split("-")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)

howMany = fn condition -> 
  Enum.reduce(low..high, {0, condition}, fn num, {count, condition} ->
    chars = Regex.scan(~r/./, Integer.to_string(num))
    adjacent = Enum.zip(chars, Enum.drop(chars, 1))
    if condition.(adjacent), do: {count + 1, condition}, else: {count, condition}
  end) |> elem(0)
end

case System.argv() do
  ["1"] ->
    howMany.(fn adjacent ->
      Enum.all?(adjacent, fn {a, b} -> a <= b end) and Enum.any?(adjacent, fn {a, b} -> a == b end)
    end) |> IO.puts

  ["2"] ->
    howMany.(fn adjacent ->
      Enum.all?(adjacent, fn {a, b} -> a <= b end) and Enum.any?(adjacent, fn {a, b} -> a == b and Enum.count(adjacent, fn x -> x == {a, b} end) == 1 end)
    end) |> IO.puts
end
