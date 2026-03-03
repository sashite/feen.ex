defmodule Sashite.Feen.ParseTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # parse/1 -- input validation
  # ===========================================================================

  describe "parse/1 input validation" do
    test "returns :not_a_string for nil" do
      assert {:error, :not_a_string} = Sashite.Feen.parse(nil)
    end

    test "returns :not_a_string for integer" do
      assert {:error, :not_a_string} = Sashite.Feen.parse(42)
    end

    test "returns :not_a_string for atom" do
      assert {:error, :not_a_string} = Sashite.Feen.parse(:chess)
    end

    test "returns :not_a_string for list" do
      assert {:error, :not_a_string} = Sashite.Feen.parse([])
    end

    test "returns :input_too_long for oversized input" do
      long_board = String.duplicate("1/", 2048) <> "1"
      input = long_board <> " / C/c"
      assert byte_size(input) > 4096
      assert {:error, :input_too_long} = Sashite.Feen.parse(input)
    end

    test "returns :non_ascii_input for byte above 127" do
      assert {:error, :non_ascii_input} = Sashite.Feen.parse(<<128>> <> " / C/c")
    end

    test "returns :invalid_field_count for empty string" do
      assert {:error, :invalid_field_count} = Sashite.Feen.parse("")
    end

    test "returns :invalid_field_count for single field" do
      assert {:error, :invalid_field_count} = Sashite.Feen.parse("invalid")
    end

    test "returns :invalid_field_count for four fields" do
      assert {:error, :invalid_field_count} = Sashite.Feen.parse("a b c d")
    end
  end

  # ===========================================================================
  # parse/1 -- piece placement errors (Field 1)
  # ===========================================================================

  describe "parse/1 piece placement errors" do
    test "returns :piece_placement_empty for empty field 1" do
      assert {:error, :piece_placement_empty} = Sashite.Feen.parse(" / C/c")
    end

    test "returns :piece_placement_starts_with_separator" do
      assert {:error, :piece_placement_starts_with_separator} =
               Sashite.Feen.parse("/8 / C/c")
    end

    test "returns :piece_placement_ends_with_separator" do
      assert {:error, :piece_placement_ends_with_separator} =
               Sashite.Feen.parse("8/ / C/c")
    end

    test "returns :dimensional_coherence_violation for double slash in 2D context" do
      assert {:error, :dimensional_coherence_violation} =
               Sashite.Feen.parse("8//8 / C/c")
    end

    test "returns :invalid_empty_count for leading zero" do
      assert {:error, :invalid_empty_count} = Sashite.Feen.parse("08/8 / C/c")
    end

    test "returns :board_not_regular when empty count exceeds rank width" do
      assert {:error, :board_not_regular} = Sashite.Feen.parse("44/8 / C/c")
    end

    test "returns :invalid_piece_token for invalid character" do
      assert {:error, :invalid_piece_token} = Sashite.Feen.parse("!/8 / C/c")
    end

    test "returns :board_not_regular for unequal rank widths" do
      assert {:error, :board_not_regular} = Sashite.Feen.parse("3/2 / C/c")
    end

    test "returns :dimensional_coherence_violation for 3D without inner separators" do
      assert {:error, :dimensional_coherence_violation} =
               Sashite.Feen.parse("ab//cd / G/g")
    end

    test "returns :exceeds_max_dimensions for 4D" do
      feen_4d = "a/b//c/d" <> "///" <> "e/f//g/h / G/g"
      assert {:error, :exceeds_max_dimensions} = Sashite.Feen.parse(feen_4d)
    end
  end

  # ===========================================================================
  # parse/1 -- hands errors (Field 2)
  # ===========================================================================

  describe "parse/1 hands errors" do
    test "returns :invalid_hands_delimiter when no slash" do
      assert {:error, :invalid_hands_delimiter} = Sashite.Feen.parse("8/8 P C/c")
    end

    test "returns :invalid_hands_delimiter when two slashes" do
      assert {:error, :invalid_hands_delimiter} = Sashite.Feen.parse("8/8 P/B/r C/c")
    end

    test "returns :invalid_hand_count for count of 0" do
      assert {:error, :invalid_hand_count} = Sashite.Feen.parse("8/8 0P/ C/c")
    end

    test "returns :invalid_hand_count for count of 1" do
      assert {:error, :invalid_hand_count} = Sashite.Feen.parse("8/8 1P/ C/c")
    end

    test "returns :invalid_hand_count for leading zero" do
      assert {:error, :invalid_hand_count} = Sashite.Feen.parse("8/8 02P/ C/c")
    end

    test "returns :invalid_piece_token for invalid character in hand" do
      assert {:error, :invalid_piece_token} = Sashite.Feen.parse("8/8 !/ C/c")
    end

    test "returns :hand_items_not_aggregated for duplicate tokens" do
      assert {:error, :hand_items_not_aggregated} = Sashite.Feen.parse("8/8 PP/ C/c")
    end

    test "returns :hand_items_not_in_canonical_order when count ascending" do
      assert {:error, :hand_items_not_in_canonical_order} =
               Sashite.Feen.parse("8/8/8/8/8/8/8/8 2P3B/ C/c")
    end

    test "returns :hand_items_not_in_canonical_order when sort key wrong" do
      assert {:error, :hand_items_not_in_canonical_order} =
               Sashite.Feen.parse("8/8/8/8/8/8/8/8 PB/ C/c")
    end
  end

  # ===========================================================================
  # parse/1 -- style-turn errors (Field 3)
  # ===========================================================================

  describe "parse/1 style-turn errors" do
    test "returns :invalid_style_turn_delimiter for missing slash" do
      assert {:error, :invalid_style_turn_delimiter} = Sashite.Feen.parse("8/8 / Cc")
    end

    test "returns :invalid_style_turn_delimiter for two slashes" do
      assert {:error, :invalid_style_turn_delimiter} = Sashite.Feen.parse("8/8 / C/c/x")
    end

    test "returns :invalid_style_token for non-letter" do
      assert {:error, :invalid_style_token} = Sashite.Feen.parse("8/8 / 1/c")
    end

    test "returns :style_tokens_same_case for both uppercase" do
      assert {:error, :style_tokens_same_case} = Sashite.Feen.parse("8/8 / C/D")
    end

    test "returns :style_tokens_same_case for both lowercase" do
      assert {:error, :style_tokens_same_case} = Sashite.Feen.parse("8/8 / c/d")
    end

    test "returns :invalid_style_token for multi-character token with slash" do
      assert {:error, :invalid_style_token} = Sashite.Feen.parse("8/8 / CC/c")
    end

    test "returns :invalid_style_token for empty token before slash" do
      assert {:error, :invalid_style_token} = Sashite.Feen.parse("8/8 / /c")
    end
  end

  # ===========================================================================
  # parse/1 -- cardinality errors
  # ===========================================================================

  describe "parse/1 cardinality errors" do
    test "returns :too_many_pieces when board + hands exceed squares" do
      assert {:error, :too_many_pieces} = Sashite.Feen.parse("K^k^ 2K^/2k^ S/s")
    end

    test "returns :too_many_pieces when hands alone exceed squares" do
      assert {:error, :too_many_pieces} = Sashite.Feen.parse("2/2 10k^/ S/s")
    end
  end

  # ===========================================================================
  # parse/1 -- dimension size limit errors
  # ===========================================================================

  describe "parse/1 dimension size limit errors" do
    test "returns :dimension_size_exceeds_limit for 1D board exceeding 255" do
      assert {:error, :dimension_size_exceeds_limit} = Sashite.Feen.parse("256 / C/c")
    end

    test "returns :dimension_size_exceeds_limit for 2D rank width exceeding 255" do
      assert {:error, :dimension_size_exceeds_limit} = Sashite.Feen.parse("256/256 / C/c")
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: empty boards
  # ===========================================================================

  describe "parse/1 empty boards" do
    test "empty 8x8 chess board" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / C/c")

      assert pos.shape == [8, 8]
      assert pos.turn == :first
      assert pos.first_player_style == "C"
      assert pos.second_player_style == "c"
      assert pos.first_player_hand == %{}
      assert pos.second_player_hand == %{}
      assert tuple_size(pos.board) == 64
      assert elem(pos.board, 0) == nil
      assert elem(pos.board, 63) == nil
    end

    test "minimal 1D empty board" do
      assert {:ok, pos} = Sashite.Feen.parse("1 / G/g")

      assert pos.shape == [1]
      assert tuple_size(pos.board) == 1
      assert elem(pos.board, 0) == nil
    end

    test "empty 3D board" do
      assert {:ok, pos} = Sashite.Feen.parse("3/3/3//3/3/3 / G/g")

      assert pos.shape == [2, 3, 3]
      assert tuple_size(pos.board) == 18
      assert Enum.all?(Tuple.to_list(pos.board), &is_nil/1)
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: 1D boards
  # ===========================================================================

  describe "parse/1 one-dimensional boards" do
    test "minimal 1D board with 1 piece" do
      assert {:ok, pos} = Sashite.Feen.parse("k^ / S/s")

      assert pos.shape == [1]
      assert elem(pos.board, 0) == "k^"
    end

    test "1D board with mixed pieces and empties" do
      assert {:ok, pos} = Sashite.Feen.parse("k^+p4+PK^ / C/c")

      assert pos.shape == [8]
      assert tuple_size(pos.board) == 8
      assert elem(pos.board, 0) == "k^"
      assert elem(pos.board, 1) == "+p"
      assert elem(pos.board, 2) == nil
      assert elem(pos.board, 5) == nil
      assert elem(pos.board, 6) == "+P"
      assert elem(pos.board, 7) == "K^"
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: 2D boards
  # ===========================================================================

  describe "parse/1 two-dimensional boards" do
    test "chess starting position" do
      feen = "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.shape == [8, 8]
      assert tuple_size(pos.board) == 64
      assert pos.turn == :first
      assert elem(pos.board, 0) == "-r"
      assert elem(pos.board, 4) == "k^"
      assert elem(pos.board, 7) == "-r"
      assert elem(pos.board, 8) == "+p"
      assert elem(pos.board, 16) == nil
      assert elem(pos.board, 56) == "-R"
      assert elem(pos.board, 60) == "K^"
      assert elem(pos.board, 63) == "-R"
    end

    test "shogi starting position" do
      feen = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.shape == [9, 9]
      assert tuple_size(pos.board) == 81
      assert pos.first_player_style == "S"
      assert elem(pos.board, 4) == "k^"
      assert elem(pos.board, 76) == "K^"
    end

    test "xiangqi starting position" do
      feen = "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.shape == [10, 9]
      assert tuple_size(pos.board) == 90
      assert pos.first_player_style == "X"
    end

    test "chess after 1.e4 (second player active)" do
      feen = "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / c/C"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.turn == :second
      assert pos.first_player_style == "C"
      assert elem(pos.board, 36) == "P"
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: 3D boards
  # ===========================================================================

  describe "parse/1 three-dimensional boards" do
    test "3D board (2x2x2)" do
      assert {:ok, pos} = Sashite.Feen.parse("ab/cd//AB/CD / G/g")

      assert pos.shape == [2, 2, 2]
      assert tuple_size(pos.board) == 8
      assert elem(pos.board, 0) == "a"
      assert elem(pos.board, 1) == "b"
      assert elem(pos.board, 2) == "c"
      assert elem(pos.board, 3) == "d"
      assert elem(pos.board, 4) == "A"
      assert elem(pos.board, 5) == "B"
      assert elem(pos.board, 6) == "C"
      assert elem(pos.board, 7) == "D"
    end

    test "raumschach 3D starting position (5x5x5)" do
      feen =
        "-rnk^n-r/+p+p+p+p+p/5/5/5" <>
          "//buqbu/+p+p+p+p+p/5/5/5" <>
          "//5/5/5/5/5" <>
          "//5/5/5/+P+P+P+P+P/BUQBU" <>
          "//5/5/5/+P+P+P+P+P/-RNK^N-R / R/r"

      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.shape == [5, 5, 5]
      assert tuple_size(pos.board) == 125
      assert pos.first_player_style == "R"
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: turn attribution
  # ===========================================================================

  describe "parse/1 turn attribution" do
    test "first player active when uppercase style leads" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 / C/c")

      assert pos.turn == :first
      assert pos.first_player_style == "C"
      assert pos.second_player_style == "c"
    end

    test "second player active when lowercase style leads" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / c/C")

      assert pos.turn == :second
      assert pos.first_player_style == "C"
      assert pos.second_player_style == "c"
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: hands
  # ===========================================================================

  describe "parse/1 hands" do
    test "empty hands" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 / C/c")

      assert pos.first_player_hand == %{}
      assert pos.second_player_hand == %{}
    end

    test "single pieces in hands" do
      feen = "r1bq1b1r/+p+p+p+p1k^+p+p/2n2n2/4p3/4P3/5N2/+P+P+P+P1+P+P+P/-RNBQK^2+R p/B C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.first_player_hand == %{"p" => 1}
      assert pos.second_player_hand == %{"B" => 1}
    end

    test "multiplicities in hands" do
      feen = "8/8/8/8/8/8/8/8 3P2B/3p2b C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.first_player_hand == %{"P" => 3, "B" => 2}
      assert pos.second_player_hand == %{"p" => 3, "b" => 2}
    end

    test "hand with one side empty" do
      feen = "7K^/8 P/ C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.first_player_hand == %{"P" => 1}
      assert pos.second_player_hand == %{}
    end

    test "enhanced piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 +P/ C/c")
      assert pos.first_player_hand == %{"+P" => 1}
    end

    test "diminished piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 -P/ C/c")
      assert pos.first_player_hand == %{"-P" => 1}
    end

    test "terminal piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 P^/ C/c")
      assert pos.first_player_hand == %{"P^" => 1}
    end

    test "enhanced terminal piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 +P^/ C/c")
      assert pos.first_player_hand == %{"+P^" => 1}
    end

    test "diminished terminal derived piece in hand" do
      feen = "8/8 -P^" <> "'" <> "/ C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert pos.first_player_hand == %{("-P^" <> "'") => 1}
    end

    test "mixed modified pieces in both hands" do
      feen = "8/8/8/8/8/8/8/8 2+P-P/+p C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert pos.first_player_hand == %{"+P" => 2, "-P" => 1}
      assert pos.second_player_hand == %{"+p" => 1}
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: EPIN modifiers
  # ===========================================================================

  describe "parse/1 EPIN modifiers" do
    test "enhanced state modifier (+)" do
      assert {:ok, pos} = Sashite.Feen.parse("+R7/8 / C/c")
      assert elem(pos.board, 0) == "+R"
    end

    test "diminished state modifier (-)" do
      assert {:ok, pos} = Sashite.Feen.parse("-R7/8 / C/c")
      assert elem(pos.board, 0) == "-R"
    end

    test "terminal marker (^)" do
      assert {:ok, pos} = Sashite.Feen.parse("K^7/8 / C/c")
      assert elem(pos.board, 0) == "K^"
    end

    test "all modifiers combined" do
      feen = "+R^" <> "'" <> "7/8 / C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert elem(pos.board, 0) == "+R^" <> "'"
    end

    test "derived piece in shogi (jeweled king)" do
      feen = "lnsgk^" <> "'" <> "gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert elem(pos.board, 4) == "k^" <> "'"
    end
  end

  # ===========================================================================
  # parse/1 -- happy paths: cross-style games
  # ===========================================================================

  describe "parse/1 cross-style games" do
    test "chess vs makruk" do
      feen = "rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/m"
      assert {:ok, pos} = Sashite.Feen.parse(feen)

      assert pos.first_player_style == "C"
      assert pos.second_player_style == "m"
    end
  end

  # ===========================================================================
  # parse!/1 -- success
  # ===========================================================================

  describe "parse!/1 success" do
    test "returns Qi struct directly" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")
      assert pos.shape == [8, 8]
      assert pos.turn == :first
    end

    test "returns same result as parse/1" do
      feen = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      {:ok, from_parse} = Sashite.Feen.parse(feen)
      from_bang = Sashite.Feen.parse!(feen)
      assert from_parse == from_bang
    end
  end

  # ===========================================================================
  # parse!/1 -- failure
  # ===========================================================================

  describe "parse!/1 failure" do
    test "raises ArgumentError on invalid input" do
      assert_raise ArgumentError, fn ->
        Sashite.Feen.parse!("invalid")
      end
    end

    test "error message contains reason atom" do
      assert_raise ArgumentError, ~r/invalid_field_count/, fn ->
        Sashite.Feen.parse!("invalid")
      end
    end

    test "error message contains the input" do
      assert_raise ArgumentError, ~r/"invalid"/, fn ->
        Sashite.Feen.parse!("invalid")
      end
    end

    test "raises for type error" do
      assert_raise ArgumentError, ~r/not_a_string/, fn ->
        Sashite.Feen.parse!(nil)
      end
    end

    test "raises for style error" do
      assert_raise ArgumentError, ~r/style_tokens_same_case/, fn ->
        Sashite.Feen.parse!("8/8 / C/D")
      end
    end
  end
end
