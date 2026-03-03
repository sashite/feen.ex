defmodule Sashite.Feen.Parser do
  @moduledoc false

  # Orchestrator for FEEN string parsing.
  #
  # Validates the input in order:
  # 1. Type check (binary)
  # 2. Byte-size bound (≤ 4096)
  # 3. ASCII-only check (single pass)
  # 4. Field split (exactly 3 fields separated by single spaces)
  # 5. Field 1 — Piece Placement (delegates to PiecePlacement)
  # 6. Field 2 — Hands (delegates to Hands)
  # 7. Field 3 — Style-Turn (delegates to StyleTurn)
  # 8. Cardinality validation (p ≤ n)
  # 9. Qi construction (only in parse/1, skipped in valid?/1)
  #
  # The validation pipeline is shared between parse/1 and valid?/1.
  # valid?/1 never constructs a Qi, avoiding allocation on the hot path.

  alias Sashite.Feen.Parser.{Hands, PiecePlacement, StyleTurn}

  # ── Public API ──────────────────────────────────────────────────────

  @doc false
  @spec parse(binary()) :: {:ok, Qi.t()} | {:error, atom()}
  def parse(input) do
    with {:ok, {flat_board, shape}, hands_result, style_result} <- validate(input) do
      {:ok, build_position(flat_board, shape, hands_result, style_result)}
    end
  end

  @doc false
  @spec valid?(term()) :: boolean()
  def valid?(input) do
    match?({:ok, _, _, _}, validate(input))
  end

  # ── Validation pipeline ─────────────────────────────────────────────
  #
  # Returns {:ok, pp_result, hands_result, style_result} or {:error, atom}.
  # pp_result is {flat_board, shape}.

  defp validate(input) when not is_binary(input), do: {:error, :not_a_string}

  defp validate(input) when byte_size(input) > 4096, do: {:error, :input_too_long}

  defp validate(input) do
    with :ok <- check_ascii(input),
         {:ok, f1, f2, f3} <- split_fields(input),
         {:ok, {flat_board, shape}} <- PiecePlacement.parse(f1),
         {:ok, hands_result} <- Hands.parse(f2),
         {:ok, style_result} <- StyleTurn.parse(f3),
         :ok <- check_cardinality(flat_board, hands_result) do
      {:ok, {flat_board, shape}, hands_result, style_result}
    end
  end

  # ── ASCII check ─────────────────────────────────────────────────────
  #
  # Single left-to-right pass. Rejects any byte > 127.
  # O(n) with early exit on first non-ASCII byte.

  defp check_ascii(<<>>), do: :ok
  defp check_ascii(<<byte, _::binary>>) when byte > 127, do: {:error, :non_ascii_input}
  defp check_ascii(<<_, rest::binary>>), do: check_ascii(rest)

  # ── Field splitting ─────────────────────────────────────────────────
  #
  # Splits on single ASCII space (0x20). The input must contain exactly
  # two spaces, yielding exactly three fields. Uses :binary.split/3 for
  # a single BIF-level pass.

  defp split_fields(input) do
    case :binary.split(input, " ", [:global]) do
      [f1, f2, f3] -> {:ok, f1, f2, f3}
      _ -> {:error, :invalid_field_count}
    end
  end

  # ── Cardinality validation ──────────────────────────────────────────
  #
  # §11.4: p ≤ n where
  #   n = total squares (length of flat_board)
  #   p = board pieces + hand pieces (both hands)

  defp check_cardinality(flat_board, hands_result) do
    total_squares = length(flat_board)
    board_pieces = count_non_nil(flat_board, 0)
    hand_pieces = length(hands_result.first) + length(hands_result.second)

    if board_pieces + hand_pieces <= total_squares do
      :ok
    else
      {:error, :too_many_pieces}
    end
  end

  defp count_non_nil([], count), do: count
  defp count_non_nil([nil | rest], count), do: count_non_nil(rest, count)
  defp count_non_nil([_ | rest], count), do: count_non_nil(rest, count + 1)

  # ── Qi construction ─────────────────────────────────────────────────
  #
  # Builds a Qi from validated, parsed components.
  # Only called from parse/1, never from valid?/1.

  defp build_position(flat_board, shape, hands_result, style_result) do
    position =
      Qi.new(shape,
        first_player_style: style_result.first_player_style,
        second_player_style: style_result.second_player_style
      )

    position = apply_board(position, flat_board, 0)
    position = apply_hand(position, :first, hands_result.first)
    position = apply_hand(position, :second, hands_result.second)

    if style_result.turn == :second do
      Qi.toggle(position)
    else
      position
    end
  end

  # Applies non-nil board squares as a single board_diff.
  # Collects {index, piece} tuples, then applies once.

  defp apply_board(position, flat_board, _start_index) do
    diffs = board_diffs(flat_board, 0, [])

    case diffs do
      [] -> position
      _ -> Qi.board_diff(position, diffs)
    end
  end

  defp board_diffs([], _index, acc), do: acc
  defp board_diffs([nil | rest], index, acc), do: board_diffs(rest, index + 1, acc)

  defp board_diffs([piece | rest], index, acc),
    do: board_diffs(rest, index + 1, [{index, piece} | acc])

  # Converts an expanded piece list into a count map, then applies as hand diff.

  defp apply_hand(position, _player, []), do: position

  defp apply_hand(position, :first, expanded) do
    Qi.first_player_hand_diff(position, to_deltas(expanded))
  end

  defp apply_hand(position, :second, expanded) do
    Qi.second_player_hand_diff(position, to_deltas(expanded))
  end

  defp to_deltas(expanded) do
    expanded
    |> to_count_map(%{})
    |> Map.to_list()
  end

  defp to_count_map([], acc), do: acc

  defp to_count_map([piece | rest], acc) do
    to_count_map(rest, Map.update(acc, piece, 1, &(&1 + 1)))
  end
end
