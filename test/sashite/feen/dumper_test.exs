defmodule Sashite.Feen.DumperTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen
  alias Sashite.Feen.Dumper
  alias Sashite.Epin
  alias Sashite.Sin

  # =============================================================================
  # Helper Functions
  # =============================================================================

  defp build_position(piece_placement, hands, style_turn) do
    %Feen{
      piece_placement: piece_placement,
      hands: hands,
      style_turn: style_turn
    }
  end

  defp empty_board_8x8 do
    segment = List.duplicate(nil, 8)

    %{
      squares: List.duplicate(segment, 8),
      separators: [1, 1, 1, 1, 1, 1, 1]
    }
  end

  defp empty_hands do
    %{first: [], second: []}
  end

  defp chess_style_turn_first_active do
    %{
      active: %Sin{style: :C, side: :first},
      inactive: %Sin{style: :C, side: :second}
    }
  end

  defp chess_style_turn_second_active do
    %{
      active: %Sin{style: :C, side: :second},
      inactive: %Sin{style: :C, side: :first}
    }
  end

  defp shogi_style_turn_first_active do
    %{
      active: %Sin{style: :S, side: :first},
      inactive: %Sin{style: :S, side: :second}
    }
  end

  defp epin(type, side, opts \\ []) do
    state = Keyword.get(opts, :state, :normal)
    terminal = Keyword.get(opts, :terminal, false)
    derived = Keyword.get(opts, :derived, false)

    pin = %Sashite.Pin{
      type: type,
      side: side,
      state: state,
      terminal: terminal
    }

    %Epin{pin: pin, derived: derived}
  end

  # =============================================================================
  # Basic Format Tests
  # =============================================================================

  describe "dump/1 output format" do
    test "produces three fields separated by single spaces" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_first_active())

      result = Dumper.dump(position)
      fields = String.split(result, " ")

      assert length(fields) == 3
    end

    test "empty 8x8 board with empty hands and Chess style" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_first_active())

      assert Dumper.dump(position) == "8/8/8/8/8/8/8/8 / C/c"
    end

    test "empty 8x8 board with second player active" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_second_active())

      assert Dumper.dump(position) == "8/8/8/8/8/8/8/8 / c/C"
    end

    test "empty 9x9 board (Shogi style)" do
      segment = List.duplicate(nil, 9)
      piece_placement = %{
        squares: List.duplicate(segment, 9),
        separators: [1, 1, 1, 1, 1, 1, 1, 1]
      }

      position = build_position(piece_placement, empty_hands(), shogi_style_turn_first_active())

      assert Dumper.dump(position) == "9/9/9/9/9/9/9/9/9 / S/s"
    end
  end

  # =============================================================================
  # Piece Placement Integration
  # =============================================================================

  describe "dump/1 piece placement integration" do
    test "single piece on board" do
      # King on first square
      king = epin(:K, :first, terminal: true)
      segment = [king | List.duplicate(nil, 7)]
      piece_placement = %{
        squares: [segment | List.duplicate(List.duplicate(nil, 8), 7)],
        separators: [1, 1, 1, 1, 1, 1, 1]
      }

      position = build_position(piece_placement, empty_hands(), chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert String.starts_with?(result, "K^7/")
    end

    test "multiple pieces on same rank" do
      # Rook, empty, empty, empty, King, empty, empty, Rook
      rook1 = epin(:R, :first)
      king = epin(:K, :first, terminal: true)
      rook2 = epin(:R, :first)
      segment = [rook1, nil, nil, nil, king, nil, nil, rook2]

      piece_placement = %{
        squares: [segment | List.duplicate(List.duplicate(nil, 8), 7)],
        separators: [1, 1, 1, 1, 1, 1, 1]
      }

      position = build_position(piece_placement, empty_hands(), chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert String.starts_with?(result, "R3K^2R/")
    end

    test "pieces with modifiers" do
      # Enhanced rook
      enhanced_rook = epin(:R, :first, state: :enhanced)
      segment = [enhanced_rook | List.duplicate(nil, 7)]

      piece_placement = %{
        squares: [segment | List.duplicate(List.duplicate(nil, 8), 7)],
        separators: [1, 1, 1, 1, 1, 1, 1]
      }

      position = build_position(piece_placement, empty_hands(), chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert String.starts_with?(result, "+R7/")
    end

    test "derived pieces" do
      # Derived pawn
      derived_pawn = epin(:P, :first, derived: true)
      segment = [derived_pawn | List.duplicate(nil, 7)]

      piece_placement = %{
        squares: [segment | List.duplicate(List.duplicate(nil, 8), 7)],
        separators: [1, 1, 1, 1, 1, 1, 1]
      }

      position = build_position(piece_placement, empty_hands(), chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert String.starts_with?(result, "P'7/")
    end

    test "multi-dimensional board with double separators" do
      segment = List.duplicate(nil, 5)
      piece_placement = %{
        squares: [segment, segment, segment, segment],
        separators: [2, 1, 2]  # // then / then //
      }

      style_turn = %{
        active: %Sin{style: :R, side: :first},
        inactive: %Sin{style: :R, side: :second}
      }

      position = build_position(piece_placement, empty_hands(), style_turn)
      result = Dumper.dump(position)

      assert result == "5//5/5//5 / R/r"
    end
  end

  # =============================================================================
  # Hands Integration
  # =============================================================================

  describe "dump/1 hands integration" do
    test "pieces in first hand only" do
      pawn = epin(:P, :first)
      hands = %{first: [pawn, pawn], second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result == "8/8/8/8/8/8/8/8 2P/ C/c"
    end

    test "pieces in second hand only" do
      pawn = epin(:P, :second)
      hands = %{first: [], second: [pawn]}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result == "8/8/8/8/8/8/8/8 /p C/c"
    end

    test "pieces in both hands" do
      pawn_first = epin(:P, :first)
      pawn_second = epin(:P, :second)
      hands = %{first: [pawn_first, pawn_first], second: [pawn_second]}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result == "8/8/8/8/8/8/8/8 2P/p C/c"
    end

    test "multiple different pieces in hand" do
      pawn = epin(:P, :first)
      bishop = epin(:B, :first)
      knight = epin(:N, :first)
      hands = %{first: [pawn, pawn, pawn, bishop, bishop, knight], second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      # Canonical order: by count desc, then letter
      # 3P, 2B, N
      assert result == "8/8/8/8/8/8/8/8 3P2BN/ C/c"
    end

    test "hands with enhanced pieces" do
      enhanced_rook = epin(:R, :first, state: :enhanced)
      hands = %{first: [enhanced_rook, enhanced_rook], second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result == "8/8/8/8/8/8/8/8 2+R/ C/c"
    end
  end

  # =============================================================================
  # Style-Turn Integration
  # =============================================================================

  describe "dump/1 style-turn integration" do
    test "Chess style, first active" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_first_active())

      assert Dumper.dump(position) =~ ~r/ C\/c$/
    end

    test "Chess style, second active" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_second_active())

      assert Dumper.dump(position) =~ ~r/ c\/C$/
    end

    test "Shogi style" do
      position = build_position(empty_board_8x8(), empty_hands(), shogi_style_turn_first_active())

      assert Dumper.dump(position) =~ ~r/ S\/s$/
    end

    test "cross-style game" do
      style_turn = %{
        active: %Sin{style: :C, side: :first},
        inactive: %Sin{style: :M, side: :second}
      }

      position = build_position(empty_board_8x8(), empty_hands(), style_turn)

      assert Dumper.dump(position) =~ ~r/ C\/m$/
    end
  end

  # =============================================================================
  # Round-Trip Tests (Parse -> Dump)
  # =============================================================================

  describe "round-trip (parse then dump)" do
    test "empty Chess board" do
      input = "8/8/8/8/8/8/8/8 / C/c"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "empty Shogi board" do
      input = "9/9/9/9/9/9/9/9/9 / S/s"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "Chess starting position" do
      input = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "Shogi starting position" do
      input = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "Xiangqi starting position" do
      input = "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "position with captures" do
      input = "8/8/8/8/8/8/8/8 2P/p C/c"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "cross-style position" do
      input = "8/8/8/8/8/8/8/8 / C/m"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "second player active" do
      input = "8/8/8/8/8/8/8/8 / c/C"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end
  end

  # =============================================================================
  # Canonicalization Tests
  # =============================================================================

  describe "canonicalization" do
    test "hands are aggregated" do
      # Input with non-aggregated pieces (P, P instead of 2P)
      pawn = epin(:P, :first)
      hands = %{first: [pawn, pawn], second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      # Should output canonical form with count
      assert result =~ "2P/"
      refute result =~ "PP/"
    end

    test "hands are sorted by count descending" do
      pawn = epin(:P, :first)
      bishop = epin(:B, :first)
      # 3 pawns, 2 bishops -> 3P2B (not 2B3P)
      hands = %{first: [pawn, pawn, pawn, bishop, bishop], second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result =~ "3P2B/"
    end

    test "hands with same count sorted alphabetically" do
      # 2 pawns, 2 bishops -> 2B2P (B before P alphabetically)
      pawn = epin(:P, :first)
      bishop = epin(:B, :first)
      hands = %{first: [pawn, pawn, bishop, bishop], second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result =~ "2B2P/"
    end

    test "empty counts merged in piece placement" do
      # Multiple consecutive empty squares should be merged
      segment = List.duplicate(nil, 8)
      piece_placement = %{
        squares: [segment],
        separators: []
      }

      style_turn = chess_style_turn_first_active()
      position = build_position(piece_placement, empty_hands(), style_turn)
      result = Dumper.dump(position)

      # Should be "8" not "11111111"
      assert String.starts_with?(result, "8 ")
    end

    test "non-canonical input is normalized on round-trip" do
      # Parse non-canonical (PP instead of 2P), dump should be canonical
      input = "8/8/8/8/8/8/8/8 PP/ C/c"
      {:ok, position} = Feen.parse(input)

      # Output should be canonical
      assert Dumper.dump(position) == "8/8/8/8/8/8/8/8 2P/ C/c"
    end
  end

  # =============================================================================
  # Complex Scenarios
  # =============================================================================

  describe "complex scenarios" do
    test "full Chess game position with captures" do
      # Simplified mid-game position
      input = "r1bqk^b1r/+p+p+p+p1+p+p+p/2n2n2/4p3/2B1P3/5N2/+P+P+P+P1+P+P+P/RNBQK^2R 2P/p C/c"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "Shogi position with pieces in hand" do
      input = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL 2P/p S/s"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "position with derived pieces" do
      input = "P'7/8/8/8/8/8/8/8 / C/m"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "position with all EPIN modifiers" do
      # +K^' = enhanced, terminal, derived
      input = "+K^'7/8/8/8/8/8/8/8 / C/m"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "3D board (Raumschach-like)" do
      input = "5//5/5//5 / R/r"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "1D board" do
      input = "k^+p4+PK^ / C/c"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end

    test "irregular board shape" do
      input = "rkr/pp/PPPP / G/g"
      {:ok, position} = Feen.parse(input)

      assert Dumper.dump(position) == input
    end
  end

  # =============================================================================
  # Edge Cases
  # =============================================================================

  describe "edge cases" do
    test "single square board" do
      king = epin(:K, :first, terminal: true)
      piece_placement = %{
        squares: [[king]],
        separators: []
      }

      position = build_position(piece_placement, empty_hands(), chess_style_turn_first_active())

      assert Dumper.dump(position) == "K^ / C/c"
    end

    test "board with only empty squares" do
      segment = List.duplicate(nil, 3)
      piece_placement = %{
        squares: [segment, segment, segment],
        separators: [1, 1]
      }

      position = build_position(piece_placement, empty_hands(), chess_style_turn_first_active())

      assert Dumper.dump(position) == "3/3/3 / C/c"
    end

    test "large number of pieces in hand" do
      pawn = epin(:P, :first)
      hands = %{first: List.duplicate(pawn, 18), second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      assert result =~ "18P/"
    end

    test "all 26 different piece types in hand" do
      pieces = for letter <- ?A..?Z do
        epin(String.to_atom(<<letter>>), :first)
      end
      hands = %{first: pieces, second: []}

      position = build_position(empty_board_8x8(), hands, chess_style_turn_first_active())
      result = Dumper.dump(position)

      # All letters should appear, sorted alphabetically
      [_, hands_field, _] = String.split(result, " ")
      [first_hand, _] = String.split(hands_field, "/")

      assert first_hand == "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    end
  end

  # =============================================================================
  # Spec Compliance
  # =============================================================================

  describe "FEEN spec compliance" do
    @tag :spec_compliance
    test "§6: three fields separated by single ASCII spaces" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_first_active())
      result = Dumper.dump(position)

      # Check format: no leading/trailing space, single spaces between fields
      refute String.starts_with?(result, " ")
      refute String.ends_with?(result, " ")
      refute result =~ "  "  # no double spaces

      fields = String.split(result, " ")
      assert length(fields) == 3
    end

    @tag :spec_compliance
    test "§6.2: ASCII-only output" do
      position = build_position(empty_board_8x8(), empty_hands(), chess_style_turn_first_active())
      result = Dumper.dump(position)

      # All characters should be ASCII (0-127)
      assert result |> String.to_charlist() |> Enum.all?(&(&1 < 128))
    end

    @tag :spec_compliance
    test "§10: output is canonical" do
      # Parse non-canonical, dump should produce canonical
      non_canonical = "8/8/8/8/8/8/8/8 PBP/ C/c"
      {:ok, position} = Feen.parse(non_canonical)

      # Canonical: 2P sorted before B? No, by count then alpha: P(2), B(1) -> 2PB
      canonical = Dumper.dump(position)

      # Re-parse and dump again should be identical
      {:ok, position2} = Feen.parse(canonical)
      assert Dumper.dump(position2) == canonical
    end
  end
end
