defmodule Sashite.Feen.Dumper do
  @moduledoc """
  Dumper (serializer) for FEEN positions.

  This module coordinates serialization of the three FEEN fields:
  1. Piece Placement (board occupancy)
  2. Hands (pieces in hand)
  3. Style-Turn (active player and styles)

  The output is always **canonical** as specified by FEEN v1.0.0.

  ## Internal Use

  This module is used internally by `Sashite.Feen.to_string/1`.
  Users should use the main `Sashite.Feen` module for serialization.
  """

  alias Sashite.Feen
  alias Sashite.Feen.Dumper.PiecePlacement
  alias Sashite.Feen.Dumper.PiecesInHand
  alias Sashite.Feen.Dumper.StyleTurn

  @doc """
  Dumps a position struct to its canonical FEEN string representation.

  ## Parameters

  - `position` - A `%Sashite.Feen{}` struct

  ## Returns

  A canonical FEEN string.

  ## Examples

      iex> position = %Sashite.Feen{...}
      iex> Sashite.Feen.Dumper.dump(position)
      "8/8/8/8/8/8/8/8 / C/c"

  """
  @spec dump(Feen.t()) :: String.t()
  def dump(%Feen{} = position) do
    piece_placement_str = PiecePlacement.dump(position.piece_placement)
    hands_str = PiecesInHand.dump(position.hands)
    style_turn_str = StyleTurn.dump(position.style_turn)

    "#{piece_placement_str} #{hands_str} #{style_turn_str}"
  end
end
