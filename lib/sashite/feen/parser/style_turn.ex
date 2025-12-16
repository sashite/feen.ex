# lib/sashite/feen/parser/style_turn.ex

defmodule Sashite.Feen.Parser.StyleTurn do
  @moduledoc """
  Parser for the Style-Turn field of FEEN notation.

  The Style-Turn field encodes:
  1. The native Piece Style associated with each Player Side
  2. The identity of the Active Player

  ## Format

      <ACTIVE-STYLE>/<INACTIVE-STYLE>

  - Each style is a valid SIN token (exactly one ASCII letter)
  - Uppercase = Side `first`, lowercase = Side `second`
  - The two tokens must be of opposite case
  - Position determines who is active (first position = active player)

  ## Examples

      iex> Sashite.Feen.Parser.StyleTurn.parse("C/c")
      {:ok, %{active: %Sashite.Sin{style: :C, side: :first}, inactive: %Sashite.Sin{style: :C, side: :second}}}

      iex> Sashite.Feen.Parser.StyleTurn.parse("c/C")
      {:ok, %{active: %Sashite.Sin{style: :C, side: :second}, inactive: %Sashite.Sin{style: :C, side: :first}}}

      iex> Sashite.Feen.Parser.StyleTurn.parse("C/C")
      {:error, "Invalid style-turn: tokens must be of opposite case"}

  """

  alias Sashite.Sin

  @type t :: %{
          active: Sin.t(),
          inactive: Sin.t()
        }

  @doc """
  Parses a style-turn string into a structured representation.

  ## Parameters

  - `string` - The style-turn field from a FEEN string

  ## Returns

  - `{:ok, %{active: %Sin{}, inactive: %Sin{}}}` on success
  - `{:error, reason}` on failure
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(string) when is_binary(string) do
    with {:ok, {active_str, inactive_str}} <- split_style_turn(string),
         {:ok, active} <- parse_sin_token(active_str, :active),
         {:ok, inactive} <- parse_sin_token(inactive_str, :inactive),
         :ok <- validate_opposite_case(active, inactive) do
      {:ok, %{active: active, inactive: inactive}}
    end
  end

  # ===========================================================================
  # Private - Field Splitting
  # ===========================================================================

  defp split_style_turn(string) do
    case String.split(string, "/") do
      [active, inactive] ->
        {:ok, {active, inactive}}

      parts ->
        {:error, "Invalid style-turn: expected exactly one '/' delimiter, got #{length(parts) - 1}"}
    end
  end

  # ===========================================================================
  # Private - Token Parsing
  # ===========================================================================

  defp parse_sin_token(token, position) do
    case Sin.parse(token) do
      {:ok, sin} ->
        {:ok, sin}

      {:error, _} ->
        {:error, "Invalid style-turn: invalid #{position} style token '#{token}'"}
    end
  end

  # ===========================================================================
  # Private - Validation
  # ===========================================================================

  defp validate_opposite_case(active, inactive) do
    active_is_first = active.side == :first
    inactive_is_first = inactive.side == :first

    if active_is_first != inactive_is_first do
      :ok
    else
      {:error, "Invalid style-turn: tokens must be of opposite case (one uppercase, one lowercase)"}
    end
  end
end
