defmodule Sashite.Feen.Dumper.StyleTurn do
  @moduledoc false

  # Serializer for the FEEN Style-Turn field (Field 3).
  #
  # Format: <ACTIVE-STYLE>/<INACTIVE-STYLE>
  #
  # The active style is the style of the player whose turn it is.
  # Uppercase = first player, lowercase = second player.
  #
  # Accepts the three Qi fields directly: turn, first_player_style,
  # second_player_style. Produces a canonical 3-byte binary.

  @doc false
  @spec dump(:first | :second, String.t(), String.t()) :: binary()
  def dump(:first, first_player_style, second_player_style) do
    <<first_player_style::binary, "/", second_player_style::binary>>
  end

  def dump(:second, first_player_style, second_player_style) do
    <<second_player_style::binary, "/", first_player_style::binary>>
  end
end
