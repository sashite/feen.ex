defmodule Sashite.Feen.Parser.PiecePlacement do
  @moduledoc """
  Parser for the Piece Placement field (Field 1) of FEEN notation.

  - One or more segments
  - Segments separated by one or more '/' (slash groups)
  - Must not start or end with '/'
  - Each segment is a concatenation of placement tokens:
    * empty-count tokens: base-10 integer >= 1, no leading zeros
    * piece tokens: valid EPIN tokens
  """

  alias Sashite.Epin

  @type segment :: [Epin.t() | nil]

  @type t :: %{
          squares: [segment()],
          separators: [pos_integer()]
        }

  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(string) when is_binary(string) do
    with :ok <- validate_not_empty(string),
         :ok <- validate_no_leading_slash(string),
         :ok <- validate_no_trailing_slash(string),
         {:ok, segments, separators} <- parse_all(string) do
      {:ok, %{squares: segments, separators: separators}}
    end
  end

  # ===========================================================================
  # Validation
  # ===========================================================================

  defp validate_not_empty(""), do: {:error, "Invalid piece placement: must not be empty"}
  defp validate_not_empty(_), do: :ok

  defp validate_no_leading_slash(string) do
    if String.starts_with?(string, "/") do
      {:error, "Invalid piece placement: must not start with /"}
    else
      :ok
    end
  end

  defp validate_no_trailing_slash(string) do
    if String.ends_with?(string, "/") do
      {:error, "Invalid piece placement: must not end with /"}
    else
      :ok
    end
  end

  # ===========================================================================
  # Top-level parsing: segment (slash_group segment)*
  # ===========================================================================

  defp parse_all(bin), do: parse_segments(bin, [], [])

  defp parse_segments(<<>>, segs_acc, seps_acc) do
    {:ok, Enum.reverse(segs_acc), Enum.reverse(seps_acc)}
  end

  defp parse_segments(bin, segs_acc, seps_acc) do
    with {:ok, segment, rest} <- parse_segment(bin) do
      segs_acc = [segment | segs_acc]

      case rest do
        <<>> ->
          parse_segments(<<>>, segs_acc, seps_acc)

        <<"/", _::binary>> ->
          {count, after_slashes} = take_slashes(rest)

          if after_slashes == <<>> do
            {:error, "Invalid piece placement: must not end with /"}
          else
            parse_segments(after_slashes, segs_acc, [count | seps_acc])
          end

        _ ->
          {:error, "Invalid piece placement: unexpected character '#{String.first(rest)}'"}
      end
    end
  end

  defp take_slashes(bin), do: take_slashes(bin, 0)

  defp take_slashes(<<"/", rest::binary>>, n), do: take_slashes(rest, n + 1)
  defp take_slashes(rest, n) when n >= 1, do: {n, rest}

  # ===========================================================================
  # Segment parsing: placement_token+
  # ===========================================================================

  defp parse_segment(bin) do
    case parse_segment_tokens(bin, [], 0) do
      {:ok, [], _rest, 0} ->
        {:error, "Invalid piece placement: empty segment"}

      {:ok, acc, rest, _count} ->
        {:ok, Enum.reverse(acc), rest}

      {:error, _} = err ->
        err
    end
  end

  defp parse_segment_tokens(<<>>, acc, count), do: {:ok, acc, <<>>, count}

  defp parse_segment_tokens(<<"/", _::binary>> = rest, acc, count),
    do: {:ok, acc, rest, count}

  defp parse_segment_tokens(<<c, _::binary>> = bin, acc, count) when c in ?0..?9 do
    with {:ok, n, rest} <- parse_empty_count_token(bin) do
      acc2 = prepend_nils(acc, n)
      parse_segment_tokens(rest, acc2, count + 1)
    end
  end

  defp parse_segment_tokens(bin, acc, count) do
    with {:ok, epin, rest} <- parse_piece_token(bin) do
      parse_segment_tokens(rest, [epin | acc], count + 1)
    end
  end

  # ===========================================================================
  # Empty-count token: digits, no leading zeros, >= 1
  # ===========================================================================

  defp parse_empty_count_token(<<first, rest::binary>>) when first in ?0..?9 do
    {n, rest2, len} = take_number(rest, first - ?0, 1)

    cond do
      len > 1 and first == ?0 ->
        {:error, "Invalid piece placement: empty count must not have leading zeros"}

      n < 1 ->
        {:error, "Invalid piece placement: empty count must be >= 1, got #{n}"}

      true ->
        {:ok, n, rest2}
    end
  end

  defp take_number(<<c, rest::binary>>, acc, len) when c in ?0..?9 do
    take_number(rest, acc * 10 + (c - ?0), len + 1)
  end

  defp take_number(rest, acc, len), do: {acc, rest, len}

  defp prepend_nils(acc, 0), do: acc
  defp prepend_nils(acc, n) when n > 0, do: prepend_nils([nil | acc], n - 1)

  # ===========================================================================
  # Piece token: maximal EPIN candidate, validated by Epin.parse/1
  # EPIN shape here: [+-]?[A-Za-z]("^")?("'")?
  # ===========================================================================

  defp parse_piece_token(bin) do
    with {:ok, token, rest} <- take_epin_candidate(bin) do
      case Epin.parse(token) do
        {:ok, epin} -> {:ok, epin, rest}
        {:error, _} -> {:error, "Invalid piece placement: invalid piece token '#{token}'"}
      end
    end
  end

  defp take_epin_candidate(<<sign, rest::binary>>) when sign in [?+, ?-] do
    with {:ok, letter, rest2} <- take_letter(rest) do
      {terminal?, rest3} = take_optional(rest2, ?^)
      {derived?, rest4} = take_optional(rest3, ?')

      token =
        <<sign, letter>> <>
          (if terminal?, do: "^", else: "") <>
          (if derived?, do: "'", else: "")

      {:ok, token, rest4}
    end
  end

  defp take_epin_candidate(<<letter, rest::binary>> = bin) do
    if (letter in ?A..?Z) or (letter in ?a..?z) do
      {terminal?, rest2} = take_optional(rest, ?^)
      {derived?, rest3} = take_optional(rest2, ?')

      token =
        <<letter>> <>
          (if terminal?, do: "^", else: "") <>
          (if derived?, do: "'", else: "")

      {:ok, token, rest3}
    else
      {:error, "Invalid piece placement: unexpected character '#{String.first(bin)}'"}
    end
  end

  defp take_letter(<<letter, rest::binary>>)
       when (letter in ?A..?Z) or (letter in ?a..?z),
       do: {:ok, letter, rest}

  defp take_letter(bin),
    do: {:error, "Invalid piece placement: unexpected character '#{String.first(bin)}'"}

  defp take_optional(<<c, rest::binary>>, wanted) when c == wanted, do: {true, rest}
  defp take_optional(rest, _wanted), do: {false, rest}
end
