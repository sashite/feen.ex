defmodule Sashite.Feen.Parser.StyleTurn do
  @moduledoc false

  # Parser for the FEEN Style-Turn field (Field 3).
  #
  # Format: <ACTIVE-STYLE>/<INACTIVE-STYLE>
  # Each style is a valid SIN token (exactly one ASCII letter).
  # The two tokens must be of opposite case.
  #
  # Returns a map with :first_player_style, :second_player_style, and :turn.
  # The styles are normalized so that the uppercase letter maps to
  # :first_player_style and the lowercase letter to :second_player_style,
  # regardless of which is active.
  #
  # Happy path: two pattern-match clauses, zero branching.
  # Error path: specific atom for each failure mode.

  @doc false
  @spec parse(binary()) :: {:ok, map()} | {:error, atom()}

  # Happy path — first player (uppercase) is active.
  def parse(<<active, ?/, inactive>>)
      when active in ?A..?Z and inactive in ?a..?z do
    {:ok, %{first_player_style: <<active>>, second_player_style: <<inactive>>, turn: :first}}
  end

  # Happy path — second player (lowercase) is active.
  def parse(<<active, ?/, inactive>>)
      when active in ?a..?z and inactive in ?A..?Z do
    {:ok, %{first_player_style: <<inactive>>, second_player_style: <<active>>, turn: :second}}
  end

  # --- Error paths (cold) ---

  # Both tokens are valid letters but same case.
  def parse(<<a, ?/, b>>)
      when (a in ?A..?Z and b in ?A..?Z) or (a in ?a..?z and b in ?a..?z) do
    {:error, :style_tokens_same_case}
  end

  # Exactly 3 bytes with slash at position 1, but at least one byte is not a letter.
  def parse(<<_, ?/, _>>) do
    {:error, :invalid_style_token}
  end

  # Everything else: wrong length, slash not at position 1, or no slash at all.
  def parse(input) when is_binary(input) do
    case count_slashes(input, 0) do
      1 -> {:error, :invalid_style_token}
      _ -> {:error, :invalid_style_turn_delimiter}
    end
  end

  # -- Private helpers --

  defp count_slashes(<<>>, count), do: count
  defp count_slashes(<<?/, rest::binary>>, count), do: count_slashes(rest, count + 1)
  defp count_slashes(<<_, rest::binary>>, count), do: count_slashes(rest, count)
end
