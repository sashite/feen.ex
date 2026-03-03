defmodule Sashite.Feen.Dumper.PiecePlacement do
  @moduledoc false

  # Serializer for the FEEN Piece Placement field (Field 1).
  #
  # Converts a Qi board (flat tuple) and shape into a canonical FEEN
  # piece placement string.
  #
  # Responsibilities:
  # - Run-length encoding of empty squares (consecutive nils -> count)
  # - Separator insertion based on shape dimensionality:
  #   * 1D [w]       — no separators
  #   * 2D [r, f]    — "/" between ranks
  #   * 3D [l, r, f] — "/" between ranks, "//" between layers
  #
  # Output is always canonical: consecutive empties merged, no leading
  # zeros (guaranteed by Integer.to_string/1).

  @doc false
  @spec dump(tuple(), [pos_integer()]) :: binary()
  def dump(board, shape) do
    squares = Tuple.to_list(board)

    case shape do
      [_width] ->
        encode_segment(squares)

      [_rank_count, file_count] ->
        squares
        |> chunk_every(file_count)
        |> Enum.map(&encode_segment/1)
        |> Enum.intersperse("/")
        |> IO.iodata_to_binary()

      [_layer_count, rank_count, file_count] ->
        rank_size = file_count
        layer_size = rank_count * file_count

        squares
        |> chunk_every(layer_size)
        |> Enum.map(fn layer_squares ->
          layer_squares
          |> chunk_every(rank_size)
          |> Enum.map(&encode_segment/1)
          |> Enum.intersperse("/")
        end)
        |> Enum.intersperse("//")
        |> IO.iodata_to_binary()
    end
  end

  # -- Segment encoding (run-length) ------------------------------------
  #
  # Encodes a single rank (list of nil | String.t()) into a binary.
  # Consecutive nils are merged into a single integer token.

  defp encode_segment(squares) do
    squares
    |> encode_tokens(0, [])
    |> IO.iodata_to_binary()
  end

  # End of rank: flush any pending empties.
  defp encode_tokens([], 0, acc), do: :lists.reverse(acc)

  defp encode_tokens([], empty_run, acc) do
    :lists.reverse([Integer.to_string(empty_run) | acc])
  end

  # Empty square: increment run counter.
  defp encode_tokens([nil | rest], empty_run, acc) do
    encode_tokens(rest, empty_run + 1, acc)
  end

  # Piece square: flush any pending empties, then emit piece.
  defp encode_tokens([piece | rest], 0, acc) do
    encode_tokens(rest, 0, [piece | acc])
  end

  defp encode_tokens([piece | rest], empty_run, acc) do
    encode_tokens(rest, 0, [piece, Integer.to_string(empty_run) | acc])
  end

  # -- List chunking ----------------------------------------------------
  #
  # Splits a flat list into sublists of exactly `size` elements.
  # Direct recursion avoids Enum protocol dispatch.

  defp chunk_every([], _size), do: []

  defp chunk_every(list, size) do
    {chunk, rest} = take_chunk(list, size, [])
    [chunk | chunk_every(rest, size)]
  end

  defp take_chunk(rest, 0, acc), do: {:lists.reverse(acc), rest}
  defp take_chunk([head | tail], n, acc), do: take_chunk(tail, n - 1, [head | acc])
end
