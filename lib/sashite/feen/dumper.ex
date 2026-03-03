defmodule Sashite.Feen.Dumper do
  @moduledoc false

  # Orchestrator for FEEN string serialization.
  #
  # Extracts the relevant fields from a Qi struct and delegates to
  # the three sub-dumpers, one per FEEN field. Concatenates the
  # results with single ASCII spaces.
  #
  # The output is always canonical: each sub-dumper guarantees
  # canonical form for its field independently.

  alias Sashite.Feen.Dumper.{Hands, PiecePlacement, StyleTurn}

  @doc false
  @spec dump(Qi.t()) :: String.t()
  def dump(position) do
    f1 = PiecePlacement.dump(position.board, position.shape)
    f2 = Hands.dump(position.first_player_hand, position.second_player_hand)
    f3 = StyleTurn.dump(position.turn, position.first_player_style, position.second_player_style)

    <<f1::binary, " ", f2::binary, " ", f3::binary>>
  end
end
