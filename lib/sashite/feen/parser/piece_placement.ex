defmodule Sashite.Feen.Parser.PiecePlacement do
  @moduledoc false

  # Parser for the FEEN Piece Placement field (Field 1).
  #
  # Parses into a flat board (list of nil | String.t()) and a shape
  # (list of dimension sizes), suitable for direct Qi construction.
  #
  # Handles 1D, 2D, and 3D boards:
  # - 1D: no separators          → shape [width]
  # - 2D: "/" separates ranks    → shape [rank_count, rank_width]
  # - 3D: "//" separates layers  → shape [layer_count, ranks_per_layer, rank_width]
  #
  # Validates:
  # - Syntactic correctness (EPIN tokens, empty counts)
  # - Canonical form (no leading zeros, no consecutive empty counts)
  # - Dimensional coherence (§7.4 — each layer must contain "/" in 3D)
  # - Board regularity (all ranks have equal width)
  # - Dimension limits (each axis ≤ 255)
  #
  # All parsing uses binary pattern matching — no String module, no regex.

  alias Sashite.Feen.Limits

  @doc false
  @spec parse(binary()) :: {:ok, {[String.t() | nil], [pos_integer()]}} | {:error, atom()}

  def parse(<<>>), do: {:error, :piece_placement_empty}
  def parse(<<?/, _::binary>>), do: {:error, :piece_placement_starts_with_separator}

  def parse(input) when is_binary(input) do
    if :binary.at(input, byte_size(input) - 1) == ?/ do
      {:error, :piece_placement_ends_with_separator}
    else
      input |> scan_max_separator(0, 0) |> parse_by_dimensions(input)
    end
  end

  defp parse_by_dimensions(max_sep, input) do
    dims = max_sep + 1

    if dims > Limits.max_dimensions() do
      {:error, :exceeds_max_dimensions}
    else
      case dims do
        1 -> parse_1d(input)
        2 -> parse_2d(input)
        3 -> parse_3d(input)
      end
    end
  end

  # ── Max separator scan ──────────────────────────────────────────────
  #
  # Finds the longest consecutive run of "/" in the input.
  # O(n) single pass, no allocation.

  defp scan_max_separator(<<>>, current, max_seen), do: max(current, max_seen)

  defp scan_max_separator(<<?/, rest::binary>>, current, max_seen),
    do: scan_max_separator(rest, current + 1, max_seen)

  defp scan_max_separator(<<_, rest::binary>>, current, max_seen),
    do: scan_max_separator(rest, 0, max(current, max_seen))

  # ── 1D ──────────────────────────────────────────────────────────────

  defp parse_1d(input) do
    with {:ok, squares} <- parse_segment(input) do
      width = length(squares)

      if width > Limits.max_dimension_size() do
        {:error, :dimension_size_exceeds_limit}
      else
        {:ok, {squares, [width]}}
      end
    end
  end

  # ── 2D ──────────────────────────────────────────────────────────────
  #
  # Split on "/" (guaranteed single slashes since max_sep == 1).
  # Validates: all ranks have equal width (regularity), dimension limits.

  defp parse_2d(input) do
    rank_strs = :binary.split(input, "/", [:global])

    with {:ok, ranks} <- parse_all_segments(rank_strs) do
      [first_rank | rest_ranks] = ranks
      rank_width = length(first_rank)
      rank_count = length(ranks)

      cond do
        rank_width > Limits.max_dimension_size() ->
          {:error, :dimension_size_exceeds_limit}

        rank_count > Limits.max_dimension_size() ->
          {:error, :dimension_size_exceeds_limit}

        not all_width?(rest_ranks, rank_width) ->
          {:error, :board_not_regular}

        true ->
          {:ok, {List.flatten(ranks), [rank_count, rank_width]}}
      end
    end
  end

  # ── 3D ──────────────────────────────────────────────────────────────
  #
  # Split on "//" for layers, then "/" for ranks within each layer.
  # Validates:
  # - Dimensional coherence: each layer has ≥ 2 ranks (§7.4)
  # - Coherence: all layers have equal rank count
  # - Regularity: all ranks across all layers have equal width
  # - Dimension limits on all three axes

  defp parse_3d(input) do
    layer_strs = :binary.split(input, "//", [:global])

    with {:ok, layers} <- parse_layers(layer_strs) do
      [[first_rank | _] = first_layer | rest_layers] = layers
      rank_width = length(first_rank)
      ranks_per_layer = length(first_layer)
      layer_count = length(layers)

      cond do
        ranks_per_layer < 2 ->
          # §7.4: structures separated by "//" must contain "/"
          {:error, :dimensional_coherence_violation}

        layer_count > Limits.max_dimension_size() ->
          {:error, :dimension_size_exceeds_limit}

        ranks_per_layer > Limits.max_dimension_size() ->
          {:error, :dimension_size_exceeds_limit}

        rank_width > Limits.max_dimension_size() ->
          {:error, :dimension_size_exceeds_limit}

        not all_layers_coherent?(rest_layers, ranks_per_layer) ->
          {:error, :dimensional_coherence_violation}

        not all_ranks_regular?(layers, rank_width) ->
          {:error, :board_not_regular}

        true ->
          {:ok, {List.flatten(layers), [layer_count, ranks_per_layer, rank_width]}}
      end
    end
  end

  # ── Layer parsing (3D) ──────────────────────────────────────────────

  defp parse_layers(layer_strs), do: parse_layers(layer_strs, [])

  defp parse_layers([], acc), do: {:ok, :lists.reverse(acc)}

  defp parse_layers([layer_str | rest], acc) do
    rank_strs = :binary.split(layer_str, "/", [:global])

    with {:ok, ranks} <- parse_all_segments(rank_strs) do
      parse_layers(rest, [ranks | acc])
    end
  end

  # ── Segment list parsing ────────────────────────────────────────────

  defp parse_all_segments(segments), do: parse_all_segments(segments, [])

  defp parse_all_segments([], acc), do: {:ok, :lists.reverse(acc)}

  defp parse_all_segments([seg | rest], acc) do
    with {:ok, squares} <- parse_segment(seg) do
      parse_all_segments(rest, [squares | acc])
    end
  end

  # ── Shape validation helpers ────────────────────────────────────────

  defp all_width?([], _width), do: true
  defp all_width?([rank | rest], width), do: length(rank) == width and all_width?(rest, width)

  defp all_layers_coherent?([], _expected), do: true

  defp all_layers_coherent?([layer | rest], expected) do
    length(layer) == expected and all_layers_coherent?(rest, expected)
  end

  defp all_ranks_regular?([], _width), do: true

  defp all_ranks_regular?([layer | rest], width) do
    all_width?(layer, width) and all_ranks_regular?(rest, width)
  end

  # ── Single segment (rank) parsing ───────────────────────────────────
  #
  # A segment is a concatenation of placement tokens:
  # - Empty-count: integer ≥ 1, no leading zeros, no consecutive counts
  # - Piece token: valid EPIN [+-]?[A-Za-z]^?'?
  #
  # Returns {:ok, [nil | String.t()]} where nil = empty square.

  # :nocov:
  defp parse_segment(<<>>), do: {:error, :empty_segment}
  # :nocov:
  defp parse_segment(input), do: parse_segment_loop(input, false, [])

  # End of segment
  defp parse_segment_loop(<<>>, _last_was_empty, acc), do: {:ok, :lists.reverse(acc)}

  # Consecutive empty counts (non-canonical)
  # :nocov:
  defp parse_segment_loop(<<byte, _::binary>>, true, _acc) when byte in ?0..?9 do
    {:error, :invalid_empty_count}
  end

  # :nocov:

  # Empty-count token
  defp parse_segment_loop(<<first_byte, _::binary>> = input, _last_was_empty, acc)
       when first_byte in ?0..?9 do
    {value, digit_count, rest} = scan_digits(input, 0, 0)

    cond do
      digit_count > 1 and first_byte == ?0 -> {:error, :invalid_empty_count}
      value < 1 -> {:error, :invalid_empty_count}
      true -> parse_segment_loop(rest, true, prepend_empties(acc, value))
    end
  end

  # Piece token
  defp parse_segment_loop(input, _last_was_empty, acc) do
    case extract_piece(input) do
      {:ok, piece, rest} -> parse_segment_loop(rest, false, [piece | acc])
      :error -> {:error, :invalid_piece_token}
    end
  end

  # ── Digit scanning ─────────────────────────────────────────────────
  #
  # Greedily consumes ASCII digits, accumulating the integer value inline.
  # Returns {value, digit_count, rest}.

  defp scan_digits(<<byte, rest::binary>>, value, count) when byte in ?0..?9 do
    scan_digits(rest, value * 10 + (byte - ?0), count + 1)
  end

  defp scan_digits(rest, value, count), do: {value, count, rest}

  # ── Empty square prepending ─────────────────────────────────────────

  defp prepend_empties(acc, 0), do: acc
  defp prepend_empties(acc, n), do: prepend_empties([nil | acc], n - 1)

  # ── EPIN token extraction ───────────────────────────────────────────
  #
  # Pattern: [+-]?[A-Za-z]^?'?
  # Consumes from the front of the binary, returns {piece_string, rest}.
  # Uses sub-binary references (O(1) via binary_part).

  defp extract_piece(input) do
    rest1 = skip_state_modifier(input)

    case rest1 do
      <<letter, rest2::binary>> when letter in ?A..?Z or letter in ?a..?z ->
        rest3 = skip_terminal(rest2)
        rest4 = skip_derived(rest3)
        piece_len = byte_size(input) - byte_size(rest4)
        {:ok, binary_part(input, 0, piece_len), rest4}

      _ ->
        :error
    end
  end

  defp skip_state_modifier(<<?-, rest::binary>>), do: rest
  defp skip_state_modifier(<<?+, rest::binary>>), do: rest
  defp skip_state_modifier(rest), do: rest

  defp skip_terminal(<<?^, rest::binary>>), do: rest
  defp skip_terminal(rest), do: rest

  defp skip_derived(<<?', rest::binary>>), do: rest
  defp skip_derived(rest), do: rest
end
