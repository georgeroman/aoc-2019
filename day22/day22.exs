defmodule Day22 do
  defp extended_gcd(a, b) do
    {last_remainder, last_x} = extended_gcd(abs(a), abs(b), 1, 0, 0, 1)
    {last_remainder, last_x * if(a < 0, do: -1, else: 1)}
  end

  defp extended_gcd(last_remainder, 0, last_x, _, _, _),
    do: {last_remainder, last_x}

  defp extended_gcd(last_remainder, remainder, last_x, x, last_y, y) do
    quotient = div(last_remainder, remainder)
    new_remainder = rem(last_remainder, remainder)
    extended_gcd(remainder, new_remainder, x, last_x - quotient * x, y, last_y - quotient * y)
  end

  def modular_inverse(x, n) do
    {_, x} = extended_gcd(x, n)
    rem(x + n, n)
  end

  def mod(x, n) do
    r = rem(x, n)
    if r < 0, do: r + n, else: r
  end

  def pow(_, 0, _), do: 1
  def pow(x, y, n) when rem(y, 2) == 1, do: mod(x * pow(x, y - 1, n), n)

  def pow(x, y, n) do
    tmp = pow(x, div(y, 2), n)
    mod(tmp * tmp, n)
  end
end

techniques =
  File.stream!("day22.input")
  |> Stream.map(fn line ->
    cond do
      String.match?(line, ~r/deal into new stack/) ->
        {"new", nil}

      String.match?(line, ~r/deal with increment/) ->
        captures = Regex.named_captures(~r/deal with increment (?<increment>[\d]+)/, line)
        {"increment", String.to_integer(captures["increment"])}

      String.match?(line, ~r/cut/) ->
        captures = Regex.named_captures(~r/cut (?<cut>[-\d]+)/, line)
        {"cut", String.to_integer(captures["cut"])}
    end
  end)

# Raw simulation of shuffling for a starting position
run_techniques = fn len, position ->
  deal_into_new_stack = fn len, position ->
    len - position - 1
  end

  cut_cards = fn len, position, cut ->
    if cut >= 0 do
      if position < cut,
        do: len - cut + position,
        else: position - cut
    else
      cut = abs(cut)

      if position < len - cut,
        do: position + cut,
        else: cut - len + position
    end
  end

  deal_with_increment = fn len, position, increment ->
    rem(increment * position, len)
  end

  techniques
  |> Enum.reduce(position, fn technique, position ->
    case technique do
      {"new", _} ->
        deal_into_new_stack.(len, position)

      {"cut", cut} ->
        cut_cards.(len, position, cut)

      {"increment", increment} ->
        deal_with_increment.(len, position, increment)
    end
  end)
end

case System.argv() do
  ["1"] ->
    len = 10007
    card = 2019

    run_techniques.(len, card)
    |> IO.puts()

  ["2"] ->
    len = 119_315_717_514_047
    times = 101_741_582_076_661
    position = 2020

    # The final position of a card after one shuffle can be represented by an equation of
    # the form `(a * pos + b) mod len` where `pos` is the starting position of the card

    # The reverse operation can also be represented by a similar equation,
    # only applying the inverse of each shuffling technique

    {a, b} =
      techniques
      |> Enum.reverse()
      # Initially, we have the equation `pos mod len`
      |> Enum.reduce({1, 0}, fn technique, {a, b} ->
        # Compose the techniques
        case technique do
          {"new", _} ->
            {-a, len - 1 - b}

          {"cut", cut} ->
            {a, b - len + cut}

          {"increment", increment} ->
            inv = Day22.modular_inverse(increment, len)
            {inv * a, inv * b}
        end
      end)
      |> (fn {a, b} -> {Day22.mod(a, len), Day22.mod(b, len)} end).()

    # In order to find the result we need to compose the previously obtained equation `times` times
    # That is `a^times * x + b * (a^(times - 1) - 1) * (a - 1)^(-1) mod len`

    (Day22.pow(a, times, len) * position +
       b * (Day22.pow(a, times, len) - 1) * Day22.modular_inverse(a - 1, len))
    |> Day22.mod(len)
    |> IO.puts()
end
