# lib/sashite/feen/parser/pieces_in_hand.ex

defmodule Sashite.Feen.Parser.PiecesInHand do
  @moduledoc """
  Parser for the Hands field of FEEN notation.

  The Hands field encodes the two protocol Hands (pieces held off-board by each player).

  ## Format

      <FIRST-HAND>/<SECOND-HAND>

  - The `/` delimiter is always present
  - Either hand may be empty (encoded as empty string)

  ## Hand Items

  Each hand is a concatenation of hand items with no separators:

      [<count>]<piece>

  - `<piece>` is a valid EPIN token
  - `<count>` is optional; if absent, multiplicity is 1; if present, must be >= 2

  ## Examples

      iex> Sashite.Feen.Parser.PiecesInHand.parse("/")
      {:ok, %{first: [], second: []}}

      iex> Sashite.Feen.Parser.PiecesInHand.parse("2P/p")
      {:ok, %{first: [%Sashite.Epin{}, %Sashite.Epin{}], second: [%Sashite.Epin{}]}}

  """

  alias Sashite.Epin

  @type t :: %{
          first: [Epin.t()],
          second: [Epin.t()]
        }

  @doc """
  Parses a hands string into a structured representation.

  ## Parameters

  - `string` - The hands field from a FEEN string

  ## Returns

  - `{:ok, %{first: [...], second: [...]}}` on success
  - `{:error, reason}` on failure
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(string) when is_binary(string) do
    with {:ok, {first_str, second_str}} <- split_hands(string),
         {:ok, first_hand} <- parse_hand(first_str, :first),
         {:ok, second_hand} <- parse_hand(second_str, :second) do
      {:ok, %{first: first_hand, second: second_hand}}
    end
  end

  # ===========================================================================
  # Private - Field Splitting
  # ===========================================================================

  defp split_hands(string) do
    case String.split(string, "/") do
      [first, second] ->
        {:ok, {first, second}}

      parts ->
        {:error, "Invalid hands field: expected exactly one '/' delimiter, got #{length(parts) - 1}"}
    end
  end

  # ===========================================================================
  # Private - Hand Parsing
  # ===========================================================================

  defp parse_hand("", _side) do
    {:ok, []}
  end

  defp parse_hand(hand_str, side) do
    parse_hand_items(hand_str, [], side)
  end

  defp parse_hand_items("", acc, _side) do
    {:ok, Enum.reverse(acc)}
  end

  defp parse_hand_items(string, acc, side) do
    case String.at(string, 0) do
      digit when digit in ~w(0 1 2 3 4 5 6 7 8 9) ->
        parse_counted_item(string, acc, side)

      _ ->
        parse_single_item(string, acc, side)
    end
  end

  defp parse_counted_item(string, acc, side) do
    {digits, rest} = extract_digits(string)

    with {:ok, count} <- parse_count(digits),
         {:ok, epin, remaining} <- extract_epin_token(rest, side) do
      pieces = List.duplicate(epin, count)
      parse_hand_items(remaining, Enum.reverse(pieces) ++ acc, side)
    end
  end

  defp parse_single_item(string, acc, side) do
    case extract_epin_token(string, side) do
      {:ok, epin, rest} ->
        parse_hand_items(rest, [epin | acc], side)

      {:error, _} = error ->
        error
    end
  end

  # ===========================================================================
  # Private - Helpers
  # ===========================================================================

  defp extract_digits(string) do
    case Regex.run(~r/^(\d+)(.*)$/, string, capture: :all_but_first) do
      [digits, rest] -> {digits, rest}
      nil -> {"", string}
    end
  end

  defp parse_count(digits) do
    # Check for leading zeros
    if String.length(digits) > 1 && String.starts_with?(digits, "0") do
      {:error, "Invalid hands field: count must not have leading zeros"}
    else
      count = String.to_integer(digits)

      if count >= 2 do
        {:ok, count}
      else
        {:error, "Invalid hands field: explicit count must be >= 2, got #{count}"}
      end
    end
  end

  defp extract_epin_token(string, side) do
    # EPIN format: [+-]?[A-Za-z]\^?'?
    case Regex.run(~r/^([+-]?[A-Za-z]\^?'?)(.*)$/, string, capture: :all_but_first) do
      [token, rest] ->
        case Epin.parse(token) do
          {:ok, epin} -> {:ok, epin, rest}
          {:error, _} -> {:error, "Invalid hands field (#{side}): invalid piece token '#{token}'"}
        end

      nil ->
        char = String.at(string, 0)
        {:error, "Invalid hands field (#{side}): unexpected character '#{char}'"}
    end
  end
end
