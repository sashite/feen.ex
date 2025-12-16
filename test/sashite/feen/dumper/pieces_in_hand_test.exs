# test/sashite/feen/dumper/pieces_in_hand_test.exs

defmodule Sashite.Feen.Dumper.PiecesInHandTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen.Dumper.PiecesInHand
  alias Sashite.Epin

  # ===========================================================================
  # Helper functions
  # ===========================================================================

  defp epin!(string) do
    Epin.parse!(string)
  end

  # ===========================================================================
  # dump/1 - Empty hands
  # ===========================================================================

  describe "dump/1 with empty hands" do
    test "dumps both hands empty" do
      hands = %{first: [], second: []}

      assert PiecesInHand.dump(hands) == "/"
    end

    test "dumps first hand empty, second with piece" do
      hands = %{first: [], second: [epin!("p")]}

      assert PiecesInHand.dump(hands) == "/p"
    end

    test "dumps first hand with piece, second empty" do
      hands = %{first: [epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "P/"
    end
  end

  # ===========================================================================
  # dump/1 - Single pieces
  # ===========================================================================

  describe "dump/1 with single pieces" do
    test "dumps single piece in first hand" do
      hands = %{first: [epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "P/"
    end

    test "dumps single piece in second hand" do
      hands = %{first: [], second: [epin!("p")]}

      assert PiecesInHand.dump(hands) == "/p"
    end

    test "dumps single piece in each hand" do
      hands = %{first: [epin!("P")], second: [epin!("p")]}

      assert PiecesInHand.dump(hands) == "P/p"
    end

    test "dumps enhanced piece" do
      hands = %{first: [epin!("+P")], second: []}

      assert PiecesInHand.dump(hands) == "+P/"
    end

    test "dumps diminished piece" do
      hands = %{first: [epin!("-P")], second: []}

      assert PiecesInHand.dump(hands) == "-P/"
    end

    test "dumps terminal piece" do
      hands = %{first: [epin!("K^")], second: []}

      assert PiecesInHand.dump(hands) == "K^/"
    end

    test "dumps derived piece" do
      hands = %{first: [epin!("P'")], second: []}

      assert PiecesInHand.dump(hands) == "P'/"
    end

    test "dumps piece with all modifiers" do
      hands = %{first: [epin!("+K^'")], second: []}

      assert PiecesInHand.dump(hands) == "+K^'/"
    end
  end

  # ===========================================================================
  # dump/1 - Aggregation (multiplicity)
  # ===========================================================================

  describe "dump/1 with aggregation" do
    test "aggregates two identical pieces" do
      hands = %{first: [epin!("P"), epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "2P/"
    end

    test "aggregates three identical pieces" do
      hands = %{first: [epin!("P"), epin!("P"), epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "3P/"
    end

    test "aggregates many identical pieces" do
      hands = %{first: List.duplicate(epin!("P"), 10), second: []}

      assert PiecesInHand.dump(hands) == "10P/"
    end

    test "does not aggregate different piece types" do
      hands = %{first: [epin!("P"), epin!("B")], second: []}

      assert PiecesInHand.dump(hands) == "BP/"
    end

    test "does not aggregate pieces with different sides" do
      hands = %{first: [epin!("P"), epin!("p")], second: []}

      assert PiecesInHand.dump(hands) == "Pp/"
    end

    test "does not aggregate pieces with different states" do
      hands = %{first: [epin!("P"), epin!("+P")], second: []}

      assert PiecesInHand.dump(hands) == "+PP/"
    end

    test "does not aggregate pieces with different terminal status" do
      hands = %{first: [epin!("K"), epin!("K^")], second: []}

      assert PiecesInHand.dump(hands) == "KK^/"
    end

    test "does not aggregate pieces with different derivation status" do
      hands = %{first: [epin!("P"), epin!("P'")], second: []}

      assert PiecesInHand.dump(hands) == "PP'/"
    end

    test "aggregates mixed with different types" do
      hands = %{first: [epin!("P"), epin!("P"), epin!("P"), epin!("B"), epin!("B")], second: []}

      assert PiecesInHand.dump(hands) == "3P2B/"
    end

    test "aggregates in second hand" do
      hands = %{first: [], second: [epin!("p"), epin!("p"), epin!("p")]}

      assert PiecesInHand.dump(hands) == "/3p"
    end

    test "aggregates in both hands" do
      hands = %{
        first: [epin!("P"), epin!("P"), epin!("B")],
        second: [epin!("p"), epin!("p")]
      }

      assert PiecesInHand.dump(hands) == "2PB/2p"
    end
  end

  # ===========================================================================
  # dump/1 - Canonical ordering: multiplicity (descending)
  # ===========================================================================

  describe "dump/1 canonical ordering by multiplicity" do
    test "orders higher multiplicity first" do
      hands = %{first: [epin!("B"), epin!("P"), epin!("P"), epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "3PB/"
    end

    test "orders with multiple different multiplicities" do
      hands = %{
        first: [
          epin!("R"),
          epin!("B"), epin!("B"),
          epin!("P"), epin!("P"), epin!("P")
        ],
        second: []
      }

      assert PiecesInHand.dump(hands) == "3P2BR/"
    end

    test "orders equal multiplicity by letter" do
      hands = %{
        first: [epin!("R"), epin!("R"), epin!("B"), epin!("B")],
        second: []
      }

      assert PiecesInHand.dump(hands) == "2B2R/"
    end
  end

  # ===========================================================================
  # dump/1 - Canonical ordering: base letter (case-insensitive alphabetical)
  # ===========================================================================

  describe "dump/1 canonical ordering by base letter" do
    test "orders alphabetically" do
      hands = %{first: [epin!("R"), epin!("B"), epin!("N")], second: []}

      assert PiecesInHand.dump(hands) == "BNR/"
    end

    test "orders A before Z" do
      hands = %{first: [epin!("Z"), epin!("A")], second: []}

      assert PiecesInHand.dump(hands) == "AZ/"
    end

    test "orders case-insensitively (same letter, different case)" do
      hands = %{first: [epin!("p"), epin!("P")], second: []}

      # P (uppercase/first) comes before p (lowercase/second)
      assert PiecesInHand.dump(hands) == "Pp/"
    end

    test "orders mixed case alphabetically" do
      hands = %{first: [epin!("r"), epin!("B"), epin!("n")], second: []}

      assert PiecesInHand.dump(hands) == "Bnr/"
    end
  end

  # ===========================================================================
  # dump/1 - Canonical ordering: letter case (uppercase before lowercase)
  # ===========================================================================

  describe "dump/1 canonical ordering by letter case" do
    test "orders uppercase before lowercase for same letter" do
      hands = %{first: [epin!("p"), epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "Pp/"
    end

    test "orders uppercase before lowercase for multiple same letters" do
      hands = %{first: [epin!("b"), epin!("B"), epin!("b"), epin!("B")], second: []}

      assert PiecesInHand.dump(hands) == "2B2b/"
    end
  end

  # ===========================================================================
  # dump/1 - Canonical ordering: state modifier (- before + before none)
  # ===========================================================================

  describe "dump/1 canonical ordering by state modifier" do
    test "orders diminished before enhanced" do
      hands = %{first: [epin!("+P"), epin!("-P")], second: []}

      assert PiecesInHand.dump(hands) == "-P+P/"
    end

    test "orders enhanced before normal" do
      hands = %{first: [epin!("P"), epin!("+P")], second: []}

      assert PiecesInHand.dump(hands) == "+PP/"
    end

    test "orders diminished before normal" do
      hands = %{first: [epin!("P"), epin!("-P")], second: []}

      assert PiecesInHand.dump(hands) == "-PP/"
    end

    test "orders all three states correctly" do
      hands = %{first: [epin!("P"), epin!("+P"), epin!("-P")], second: []}

      assert PiecesInHand.dump(hands) == "-P+PP/"
    end

    test "orders states with multiple pieces" do
      hands = %{
        first: [epin!("P"), epin!("P"), epin!("+P"), epin!("-P"), epin!("-P")],
        second: []
      }

      assert PiecesInHand.dump(hands) == "2-P2P+P/"
    end
  end

  # ===========================================================================
  # dump/1 - Canonical ordering: terminal marker (absent before present)
  # ===========================================================================

  describe "dump/1 canonical ordering by terminal marker" do
    test "orders non-terminal before terminal" do
      hands = %{first: [epin!("K^"), epin!("K")], second: []}

      assert PiecesInHand.dump(hands) == "KK^/"
    end

    test "orders terminal after non-terminal with same other attributes" do
      hands = %{first: [epin!("+K^"), epin!("+K")], second: []}

      assert PiecesInHand.dump(hands) == "+K+K^/"
    end
  end

  # ===========================================================================
  # dump/1 - Canonical ordering: derivation marker (absent before present)
  # ===========================================================================

  describe "dump/1 canonical ordering by derivation marker" do
    test "orders native before derived" do
      hands = %{first: [epin!("P'"), epin!("P")], second: []}

      assert PiecesInHand.dump(hands) == "PP'/"
    end

    test "orders derivation after terminal" do
      hands = %{first: [epin!("K^'"), epin!("K^")], second: []}

      assert PiecesInHand.dump(hands) == "K^K^'/"
    end

    test "orders all modifiers correctly" do
      hands = %{
        first: [epin!("+K^'"), epin!("+K^"), epin!("+K'"), epin!("+K")],
        second: []
      }

      assert PiecesInHand.dump(hands) == "+K+K'+K^+K^'/"
    end
  end

  # ===========================================================================
  # dump/1 - Complex canonical ordering
  # ===========================================================================

  describe "dump/1 complex canonical ordering" do
    test "applies all ordering rules in priority" do
      hands = %{
        first: [
          epin!("R"),              # 1x R (normal)
          epin!("P"), epin!("P"),  # 2x P (normal)
          epin!("B"), epin!("B"), epin!("B")  # 3x B (normal)
        ],
        second: []
      }

      # Order: 3B (highest count), 2P, R
      assert PiecesInHand.dump(hands) == "3B2PR/"
    end

    test "complex ordering with states and sides" do
      hands = %{
        first: [
          epin!("+P"),   # enhanced P (first)
          epin!("P"),    # normal P (first)
          epin!("-P"),   # diminished P (first)
          epin!("+p"),   # enhanced p (second)
          epin!("p"),    # normal p (second)
        ],
        second: []
      }

      # All same multiplicity (1), same letter (P)
      # First: uppercase before lowercase
      # Within uppercase: - before + before normal
      # Within lowercase: - before + before normal
      assert PiecesInHand.dump(hands) == "-P+PP+pp/"
    end

    test "realistic shogi hand" do
      hands = %{
        first: [
          epin!("P"), epin!("P"), epin!("P"), epin!("P"), epin!("P"),  # 5x P
          epin!("L"), epin!("L"),  # 2x L
          epin!("N"),              # 1x N
          epin!("S"),              # 1x S
          epin!("G"),              # 1x G
          epin!("B"),              # 1x B
        ],
        second: [
          epin!("p"), epin!("p"),  # 2x p
        ]
      }

      # First hand: 5P, 2L, then alphabetical: B, G, N, S
      assert PiecesInHand.dump(hands) == "5P2LBGNS/2p"
    end
  end

  # ===========================================================================
  # dump/1 - Edge cases
  # ===========================================================================

  describe "dump/1 edge cases" do
    test "handles very large hand" do
      hands = %{first: List.duplicate(epin!("P"), 100), second: []}

      assert PiecesInHand.dump(hands) == "100P/"
    end

    test "handles all 26 different piece types" do
      pieces = for letter <- ?A..?Z, do: epin!(<<letter>>)
      hands = %{first: pieces, second: []}

      assert PiecesInHand.dump(hands) == "ABCDEFGHIJKLMNOPQRSTUVWXYZ/"
    end

    test "handles mixed hands with many pieces" do
      hands = %{
        first: List.duplicate(epin!("P"), 5) ++ List.duplicate(epin!("B"), 2) ++ [epin!("R")],
        second: List.duplicate(epin!("p"), 3) ++ [epin!("n")]
      }

      assert PiecesInHand.dump(hands) == "5P2BR/3pn"
    end
  end

  # ===========================================================================
  # Round-trip tests
  # ===========================================================================

  describe "round-trip with parser" do
    alias Sashite.Feen.Parser.PiecesInHand, as: Parser

    test "round-trips empty hands" do
      original = "/"
      {:ok, parsed} = Parser.parse(original)

      assert PiecesInHand.dump(parsed) == original
    end

    test "round-trips single piece" do
      original = "P/"
      {:ok, parsed} = Parser.parse(original)

      assert PiecesInHand.dump(parsed) == original
    end

    test "round-trips aggregated pieces" do
      original = "3P2B/"
      {:ok, parsed} = Parser.parse(original)

      assert PiecesInHand.dump(parsed) == original
    end

    test "round-trips pieces in both hands" do
      original = "3P2BR/2pn"
      {:ok, parsed} = Parser.parse(original)

      assert PiecesInHand.dump(parsed) == original
    end

    test "round-trips pieces with modifiers" do
      original = "+K^/"
      {:ok, parsed} = Parser.parse(original)

      assert PiecesInHand.dump(parsed) == original
    end

    test "round-trips derived pieces" do
      original = "P'/p'"
      {:ok, parsed} = Parser.parse(original)

      assert PiecesInHand.dump(parsed) == original
    end

    test "normalizes non-canonical input to canonical form" do
      # Non-canonical: not aggregated, wrong order
      non_canonical = "PBP/"
      {:ok, parsed} = Parser.parse(non_canonical)

      # Should produce canonical output
      assert PiecesInHand.dump(parsed) == "2PB/"
    end

    test "normalizes complex non-canonical input" do
      # Non-canonical order
      non_canonical = "RPBB/"
      {:ok, parsed} = Parser.parse(non_canonical)

      # Should produce canonical output: 2B first (higher count), then P, then R
      assert PiecesInHand.dump(parsed) == "2BPR/"
    end
  end
end
