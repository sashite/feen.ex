# test/sashite/feen/dumper/piece_placement_test.exs

defmodule Sashite.Feen.Dumper.PiecePlacementTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen.Dumper.PiecePlacement
  alias Sashite.Epin

  # ===========================================================================
  # Helper functions
  # ===========================================================================

  defp epin!(string) do
    Epin.parse!(string)
  end

  # ===========================================================================
  # dump/1 - Empty squares
  # ===========================================================================

  describe "dump/1 with empty squares" do
    test "dumps single empty square" do
      piece_placement = %{squares: [[nil]], separators: []}

      assert PiecePlacement.dump(piece_placement) == "1"
    end

    test "dumps multiple empty squares in one segment" do
      piece_placement = %{squares: [[nil, nil, nil, nil, nil, nil, nil, nil]], separators: []}

      assert PiecePlacement.dump(piece_placement) == "8"
    end

    test "dumps empty 8x8 board" do
      row = List.duplicate(nil, 8)
      squares = List.duplicate(row, 8)
      separators = List.duplicate(1, 7)
      piece_placement = %{squares: squares, separators: separators}

      assert PiecePlacement.dump(piece_placement) == "8/8/8/8/8/8/8/8"
    end

    test "dumps empty 9x9 board (shogi)" do
      row = List.duplicate(nil, 9)
      squares = List.duplicate(row, 9)
      separators = List.duplicate(1, 8)
      piece_placement = %{squares: squares, separators: separators}

      assert PiecePlacement.dump(piece_placement) == "9/9/9/9/9/9/9/9/9"
    end

    test "dumps large empty count" do
      piece_placement = %{squares: [[nil] ++ List.duplicate(nil, 99)], separators: []}

      assert PiecePlacement.dump(piece_placement) == "100"
    end
  end

  # ===========================================================================
  # dump/1 - Pieces only
  # ===========================================================================

  describe "dump/1 with pieces only" do
    test "dumps single piece" do
      piece_placement = %{squares: [[epin!("K")]], separators: []}

      assert PiecePlacement.dump(piece_placement) == "K"
    end

    test "dumps multiple pieces in one segment" do
      squares = [[epin!("R"), epin!("N"), epin!("B"), epin!("Q"), epin!("K"), epin!("B"), epin!("N"), epin!("R")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "RNBQKBNR"
    end

    test "dumps pieces with different sides" do
      squares = [[epin!("K"), epin!("k")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "Kk"
    end

    test "dumps enhanced pieces" do
      squares = [[epin!("+R"), epin!("+N"), epin!("+B")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "+R+N+B"
    end

    test "dumps diminished pieces" do
      squares = [[epin!("-R"), epin!("-N"), epin!("-B")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "-R-N-B"
    end

    test "dumps terminal pieces" do
      squares = [[epin!("K^"), epin!("k^")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "K^k^"
    end

    test "dumps derived pieces" do
      squares = [[epin!("K'"), epin!("k'")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "K'k'"
    end

    test "dumps pieces with all modifiers" do
      squares = [[epin!("+K^'"), epin!("-k^'")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "+K^'-k^'"
    end
  end

  # ===========================================================================
  # dump/1 - Mixed pieces and empty squares
  # ===========================================================================

  describe "dump/1 with mixed content" do
    test "dumps piece followed by empty squares" do
      squares = [[epin!("K"), nil, nil, nil]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "K3"
    end

    test "dumps empty squares followed by piece" do
      squares = [[nil, nil, nil, epin!("K")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "3K"
    end

    test "dumps piece surrounded by empty squares" do
      squares = [[nil, nil, epin!("K"), nil, nil]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "2K2"
    end

    test "dumps alternating pieces and empty squares" do
      squares = [[epin!("R"), nil, nil, epin!("K"), nil, nil, epin!("R")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "R2K2R"
    end

    test "dumps chess starting rank 8 (black pieces)" do
      squares = [[epin!("+r"), epin!("+n"), epin!("+b"), epin!("+q"), epin!("+k^"), epin!("+b"), epin!("+n"), epin!("+r")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "+r+n+b+q+k^+b+n+r"
    end

    test "dumps chess starting rank 7 (black pawns)" do
      squares = [List.duplicate(epin!("+p"), 8)]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "+p+p+p+p+p+p+p+p"
    end

    test "dumps shogi rank with bishop and rook" do
      squares = [[nil, epin!("r"), nil, nil, nil, nil, nil, epin!("b"), nil]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "1r5b1"
    end
  end

  # ===========================================================================
  # dump/1 - Multiple segments
  # ===========================================================================

  describe "dump/1 with multiple segments" do
    test "dumps two segments with single separator" do
      squares = [[nil, nil], [nil, nil]]
      piece_placement = %{squares: squares, separators: [1]}

      assert PiecePlacement.dump(piece_placement) == "2/2"
    end

    test "dumps multiple segments with pieces" do
      squares = [
        [epin!("R"), epin!("N")],
        [epin!("P"), epin!("P")],
        [nil, nil]
      ]
      piece_placement = %{squares: squares, separators: [1, 1]}

      assert PiecePlacement.dump(piece_placement) == "RN/PP/2"
    end

    test "dumps chess starting position structure" do
      rank8 = [epin!("+r"), epin!("+n"), epin!("+b"), epin!("+q"), epin!("+k^"), epin!("+b"), epin!("+n"), epin!("+r")]
      rank7 = List.duplicate(epin!("+p"), 8)
      empty_rank = List.duplicate(nil, 8)
      rank2 = List.duplicate(epin!("+P"), 8)
      rank1 = [epin!("+R"), epin!("+N"), epin!("+B"), epin!("+Q"), epin!("+K^"), epin!("+B"), epin!("+N"), epin!("+R")]

      squares = [rank8, rank7, empty_rank, empty_rank, empty_rank, empty_rank, rank2, rank1]
      piece_placement = %{squares: squares, separators: [1, 1, 1, 1, 1, 1, 1]}

      result = PiecePlacement.dump(piece_placement)

      assert result == "+r+n+b+q+k^+b+n+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+R+N+B+Q+K^+B+N+R"
    end
  end

  # ===========================================================================
  # dump/1 - Multi-dimensional boards (multiple slashes)
  # ===========================================================================

  describe "dump/1 with multi-dimensional boards" do
    test "dumps board with double slash separator" do
      squares = [[nil, nil], [nil, nil], [nil, nil], [nil, nil]]
      piece_placement = %{squares: squares, separators: [1, 2, 1]}

      assert PiecePlacement.dump(piece_placement) == "2/2//2/2"
    end

    test "dumps board with triple slash separator" do
      squares = [[nil, nil], [nil, nil]]
      piece_placement = %{squares: squares, separators: [3]}

      assert PiecePlacement.dump(piece_placement) == "2///2"
    end

    test "dumps 3D board structure" do
      # Simulating a 3D board with // between layers
      layer1_rank1 = [epin!("K"), nil, nil]
      layer1_rank2 = [nil, nil, nil]
      layer2_rank1 = [nil, nil, nil]
      layer2_rank2 = [nil, nil, epin!("k")]

      squares = [layer1_rank1, layer1_rank2, layer2_rank1, layer2_rank2]
      # Single slash between ranks within layer, double slash between layers
      piece_placement = %{squares: squares, separators: [1, 2, 1]}

      assert PiecePlacement.dump(piece_placement) == "K2/3//3/2k"
    end

    test "dumps mixed separator counts" do
      squares = [[nil], [nil], [nil], [nil], [nil]]
      piece_placement = %{squares: squares, separators: [1, 2, 1, 3]}

      assert PiecePlacement.dump(piece_placement) == "1/1//1/1///1"
    end
  end

  # ===========================================================================
  # dump/1 - Run-length encoding
  # ===========================================================================

  describe "dump/1 run-length encoding" do
    test "merges consecutive empty squares" do
      squares = [[nil, nil, nil, epin!("K"), nil, nil, nil, nil]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "3K4"
    end

    test "does not merge empty squares across pieces" do
      squares = [[nil, epin!("K"), nil]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "1K1"
    end

    test "handles single empty squares correctly" do
      squares = [[nil, epin!("K"), nil, epin!("Q"), nil]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "1K1Q1"
    end

    test "handles long runs of empty squares" do
      squares = [[nil] ++ List.duplicate(nil, 18) ++ [epin!("K")]]
      piece_placement = %{squares: squares, separators: []}

      assert PiecePlacement.dump(piece_placement) == "19K"
    end
  end

  # ===========================================================================
  # Round-trip tests
  # ===========================================================================

  describe "round-trip with parser" do
    alias Sashite.Feen.Parser.PiecePlacement, as: Parser

    test "round-trips empty board" do
      original = "8/8/8/8/8/8/8/8"
      {:ok, parsed} = Parser.parse(original)

      assert PiecePlacement.dump(parsed) == original
    end

    test "round-trips board with pieces" do
      original = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
      {:ok, parsed} = Parser.parse(original)

      assert PiecePlacement.dump(parsed) == original
    end

    test "round-trips board with enhanced pieces" do
      original = "+r+n+b+q+k^+b+n+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+R+N+B+Q+K^+B+N+R"
      {:ok, parsed} = Parser.parse(original)

      assert PiecePlacement.dump(parsed) == original
    end

    test "round-trips board with mixed content" do
      original = "1r5b1/ppppppppp/9/9/9/9/PPPPPPPPP/1B5R1"
      {:ok, parsed} = Parser.parse(original)

      assert PiecePlacement.dump(parsed) == original
    end

    test "round-trips 3D board with double slashes" do
      original = "K2/3//3/2k"
      {:ok, parsed} = Parser.parse(original)

      assert PiecePlacement.dump(parsed) == original
    end

    test "round-trips board with derived pieces" do
      original = "K'/7"
      {:ok, parsed} = Parser.parse(original)

      assert PiecePlacement.dump(parsed) == original
    end
  end
end
