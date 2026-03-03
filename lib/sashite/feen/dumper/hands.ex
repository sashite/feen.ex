defmodule Sashite.Feen.Dumper.Hands do
  @moduledoc false

  # Serializer for the FEEN Hands field (Field 2).
  #
  # Format: <FIRST-HAND>/<SECOND-HAND>
  #
  # Each hand is a Qi count map (%{String.t() => pos_integer()}).
  # Items are serialized in canonical order:
  #   1. Multiplicity descending
  #   2. Sort key ascending (base letter, case, state, terminal, derived)
  #
  # The sort key encoding is identical to Parser.Hands, ensuring
  # round-trip consistency: dump(parse(s)) == s for canonical input.

  @doc false
  @spec dump(%{String.t() => pos_integer()}, %{String.t() => pos_integer()}) :: binary()
  def dump(first_player_hand, second_player_hand) do
    first = dump_hand(first_player_hand)
    second = dump_hand(second_player_hand)
    <<first::binary, "/", second::binary>>
  end

  # ── Single hand serialization ───────────────────────────────────────

  defp dump_hand(hand) when map_size(hand) == 0, do: <<>>

  defp dump_hand(hand) do
    hand
    |> Map.to_list()
    |> Enum.map(fn {piece, count} -> {count, sort_key(piece), piece} end)
    |> Enum.sort(&canonical_order/2)
    |> Enum.map(&format_item/1)
    |> IO.iodata_to_binary()
  end

  # ── Canonical ordering ──────────────────────────────────────────────
  #
  # Primary: count descending. Secondary: sort_key ascending.

  defp canonical_order({count_a, key_a, _}, {count_b, key_b, _}) do
    count_a > count_b or (count_a == count_b and key_a <= key_b)
  end

  # ── Item formatting ─────────────────────────────────────────────────
  #
  # Count 1 is implicit (no prefix). Count ≥ 2 is explicit.

  defp format_item({1, _key, piece}), do: piece
  defp format_item({count, _key, piece}), do: [Integer.to_string(count), piece]

  # ── Sort key computation ────────────────────────────────────────────
  #
  # Encodes all 5 ordering criteria into a single integer:
  #   base_letter (1..26) × 32  +  case_rank (0|1) × 16  +
  #   state_rank (0|1|2) × 4    +  terminal (0|1) × 2    +  derived (0|1)
  #
  # Matches Parser.Hands exactly for round-trip consistency.

  defp sort_key(piece), do: compute_sort_key(piece)

  defp compute_sort_key(<<?-, rest::binary>>), do: compute_letter(rest, 0)
  defp compute_sort_key(<<?+, rest::binary>>), do: compute_letter(rest, 1)
  defp compute_sort_key(rest), do: compute_letter(rest, 2)

  defp compute_letter(<<letter, rest::binary>>, state_rank) when letter in ?A..?Z do
    base_letter = letter - ?A + 1
    compute_suffix(rest, base_letter, 0, state_rank)
  end

  defp compute_letter(<<letter, rest::binary>>, state_rank) when letter in ?a..?z do
    base_letter = letter - ?a + 1
    compute_suffix(rest, base_letter, 1, state_rank)
  end

  defp compute_suffix(<<?^, rest::binary>>, base_letter, case_rank, state_rank) do
    derived = derived_rank(rest)
    base_letter * 32 + case_rank * 16 + state_rank * 4 + 1 * 2 + derived
  end

  defp compute_suffix(<<?', _::binary>>, base_letter, case_rank, state_rank) do
    base_letter * 32 + case_rank * 16 + state_rank * 4 + 0 * 2 + 1
  end

  defp compute_suffix(<<>>, base_letter, case_rank, state_rank) do
    base_letter * 32 + case_rank * 16 + state_rank * 4
  end

  defp derived_rank(<<?', _::binary>>), do: 1
  defp derived_rank(_), do: 0
end
