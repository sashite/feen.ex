defmodule Sashite.Feen.Parser.Hands do
  @moduledoc false

  # Parser for the FEEN Hands field (Field 2).
  #
  # Format: <FIRST-HAND>/<SECOND-HAND>
  # Exactly one "/" delimiter must be present.
  #
  # Each hand is a concatenation of [count]<EPIN-token> items where:
  # - Count is optional (absent = 1, explicit ≥ 2, no leading zeros)
  # - EPIN token matches [+-]?[A-Za-z]^?'?
  #
  # Canonical order is enforced during parsing:
  # 1. Multiplicity descending
  # 2. Sort key ascending (encodes letter, case, state, terminal, derived)
  #
  # Identical EPIN tokens must be aggregated (not repeated separately).
  #
  # Returns expanded piece lists: each hand is a flat list of piece strings,
  # e.g. "2PB" → ["P", "P", "B"].

  @doc false
  @spec parse(binary()) :: {:ok, map()} | {:error, atom()}
  def parse(input) when is_binary(input) do
    case find_single_slash(input, 0) do
      {:ok, slash_pos} ->
        first_str = binary_part(input, 0, slash_pos)
        second_start = slash_pos + 1
        second_str = binary_part(input, second_start, byte_size(input) - second_start)

        with {:ok, first} <- parse_hand(first_str),
             {:ok, second} <- parse_hand(second_str) do
          {:ok, %{first: first, second: second}}
        end

      :error ->
        {:error, :invalid_hands_delimiter}
    end
  end

  # -- Slash detection --

  defp find_single_slash(<<>>, _pos), do: :error

  defp find_single_slash(<<?/, rest::binary>>, pos) do
    if has_slash?(rest), do: :error, else: {:ok, pos}
  end

  defp find_single_slash(<<_, rest::binary>>, pos), do: find_single_slash(rest, pos + 1)

  defp has_slash?(<<>>), do: false
  defp has_slash?(<<?/, _::binary>>), do: true
  defp has_slash?(<<_, rest::binary>>), do: has_slash?(rest)

  # -- Single hand parsing --

  defp parse_hand(<<>>), do: {:ok, []}

  defp parse_hand(input) do
    case parse_items(input, nil, 0, 0, []) do
      {:ok, items} -> {:ok, expand(items)}
      {:error, _} = error -> error
    end
  end

  # -- Recursive item extraction --

  defp parse_items(<<>>, _prev_piece, _prev_count, _prev_key, acc) do
    {:ok, :lists.reverse(acc)}
  end

  defp parse_items(input, prev_piece, prev_count, prev_key, acc) do
    with {:ok, count, rest} <- extract_count(input),
         {:ok, piece, sort_key, rest2} <- extract_epin_token(rest),
         :ok <- check_canonical(prev_piece, prev_count, prev_key, piece, count, sort_key) do
      parse_items(rest2, piece, count, sort_key, [{count, piece} | acc])
    end
  end

  # -- Count extraction --

  defp extract_count(<<byte, _::binary>> = input) when byte in ?0..?9 do
    {count, digit_count, rest} = scan_digits(input, 0, 0)

    cond do
      digit_count > 1 and byte == ?0 -> {:error, :invalid_hand_count}
      count < 2 -> {:error, :invalid_hand_count}
      true -> {:ok, count, rest}
    end
  end

  defp extract_count(input), do: {:ok, 1, input}

  defp scan_digits(<<byte, rest::binary>>, value, digits) when byte in ?0..?9 do
    scan_digits(rest, value * 10 + (byte - ?0), digits + 1)
  end

  defp scan_digits(rest, value, digits), do: {value, digits, rest}

  # -- EPIN token extraction with inline sort key computation --
  #
  # Sort key encodes all 5 canonical ordering criteria into a single integer:
  #   base_letter (1..26) × 32  +  case_rank (0|1) × 16  +
  #   state_rank (0|1|2) × 4    +  terminal (0|1) × 2    +  derived (0|1)
  #
  # This matches the Ruby implementation's bit-packed sort key exactly.

  defp extract_epin_token(input) do
    {state_rank, rest1} = extract_state_modifier(input)

    case rest1 do
      <<letter, rest2::binary>> when letter in ?A..?Z or letter in ?a..?z ->
        case_rank = if letter <= ?Z, do: 0, else: 1
        lowered = if letter <= ?Z, do: letter + 32, else: letter

        {terminal_rank, rest3} = extract_terminal(rest2)
        {derived_rank, rest4} = extract_derived(rest3)

        piece_len = byte_size(input) - byte_size(rest4)
        piece = binary_part(input, 0, piece_len)

        base_letter = lowered - ?a + 1

        sort_key =
          base_letter * 32 + case_rank * 16 + state_rank * 4 + terminal_rank * 2 + derived_rank

        {:ok, piece, sort_key, rest4}

      _ ->
        {:error, :invalid_piece_token}
    end
  end

  defp extract_state_modifier(<<?-, rest::binary>>), do: {0, rest}
  defp extract_state_modifier(<<?+, rest::binary>>), do: {1, rest}
  defp extract_state_modifier(rest), do: {2, rest}

  defp extract_terminal(<<?^, rest::binary>>), do: {1, rest}
  defp extract_terminal(rest), do: {0, rest}

  defp extract_derived(<<?', rest::binary>>), do: {1, rest}
  defp extract_derived(rest), do: {0, rest}

  # -- Canonical order check --
  #
  # Rules (from spec §11.2):
  # - Identical pieces must be aggregated (not repeated as separate items)
  # - Items sorted by multiplicity descending, then sort_key ascending

  defp check_canonical(nil, _pc, _pk, _piece, _count, _key), do: :ok

  defp check_canonical(prev_piece, prev_count, prev_key, piece, count, sort_key) do
    cond do
      piece == prev_piece ->
        {:error, :hand_items_not_aggregated}

      prev_count == count and prev_key >= sort_key ->
        {:error, :hand_items_not_in_canonical_order}

      prev_count < count ->
        {:error, :hand_items_not_in_canonical_order}

      true ->
        :ok
    end
  end

  # -- Item expansion --
  #
  # Converts [{2, "P"}, {1, "B"}] into ["P", "P", "B"].

  defp expand(items) do
    Enum.flat_map(items, fn {count, piece} -> List.duplicate(piece, count) end)
  end
end
