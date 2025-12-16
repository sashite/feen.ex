defmodule Sashite.Feen.Parser do
  @moduledoc """
  Parser for FEEN (Field Expression Encoding Notation) strings.

  This module coordinates parsing of the three FEEN fields:
  1. Piece Placement (board occupancy)
  2. Hands (pieces in hand)
  3. Style-Turn (active player and styles)

  ## Internal Use

  This module is used internally by `Sashite.Feen.parse/1`.
  Users should use the main `Sashite.Feen` module for parsing.
  """

  alias Sashite.Feen
  alias Sashite.Feen.Parser.PiecePlacement
  alias Sashite.Feen.Parser.PiecesInHand
  alias Sashite.Feen.Parser.StyleTurn

  @doc """
  Parses a FEEN string into a position struct.

  ## Parameters

  - `feen_string` - A valid FEEN string

  ## Returns

  - `{:ok, %Sashite.Feen{}}` on success
  - `{:error, reason}` on failure
  """
  @spec parse(String.t()) :: {:ok, Feen.t()} | {:error, String.t()}
  def parse(feen_string) when is_binary(feen_string) do
    with :ok <- validate_no_leading_trailing_whitespace(feen_string),
         :ok <- validate_no_line_breaks(feen_string),
         :ok <- validate_ascii_only(feen_string),
         {:ok, [piece_placement_str, hands_str, style_turn_str]} <- split_fields(feen_string),
         {:ok, piece_placement} <- PiecePlacement.parse(piece_placement_str),
         {:ok, hands} <- PiecesInHand.parse(hands_str),
         {:ok, style_turn} <- StyleTurn.parse(style_turn_str) do
      {:ok,
       %Feen{
         piece_placement: piece_placement,
         hands: hands,
         style_turn: style_turn
       }}
    end
  end

  # ===========================================================================
  # Private - Validation
  # ===========================================================================

  defp validate_no_leading_trailing_whitespace(string) do
    trimmed = String.trim(string)

    if string == trimmed do
      :ok
    else
      {:error, "Invalid FEEN string: must not contain leading or trailing whitespace"}
    end
  end

  defp validate_no_line_breaks(string) do
    if String.contains?(string, ["\r", "\n"]) do
      {:error, "Invalid FEEN string: must not contain line breaks"}
    else
      :ok
    end
  end

  defp validate_ascii_only(string) do
    if String.match?(string, ~r/^[\x00-\x7F]*$/) do
      :ok
    else
      {:error, "Invalid FEEN string: must contain only ASCII characters"}
    end
  end

  # ===========================================================================
  # Private - Field Splitting
  # ===========================================================================

  defp split_fields(feen_string) do
    fields = String.split(feen_string, " ")

    if length(fields) == 3 do
      {:ok, fields}
    else
      {:error, "Invalid FEEN string: expected exactly 3 fields separated by spaces, got #{length(fields)}"}
    end
  end
end
