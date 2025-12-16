defmodule Sashite.Feen.ParserTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen
  alias Sashite.Feen.Parser
  alias Sashite.Epin
  alias Sashite.Sin

  # =============================================================================
  # Valid FEEN Strings - Basic
  # =============================================================================

  describe "parse/1 with valid basic FEEN strings" do
    test "empty 8x8 board, empty hands, Chess style first active" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")

      assert %Feen{} = position
      assert position.style_turn.active.side == :first
      assert position.style_turn.active.style == :C
    end

    test "empty 8x8 board, empty hands, second player active" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / c/C")

      assert position.style_turn.active.side == :second
    end

    test "empty 9x9 board (Shogi)" do
      assert {:ok, position} = Parser.parse("9/9/9/9/9/9/9/9/9 / S/s")

      assert position.style_turn.active.style == :S
    end

    test "empty 10x9 board (Xiangqi)" do
      assert {:ok, position} = Parser.parse("9/9/9/9/9/9/9/9/9/9 / X/x")

      # 10 segments of 9 squares each
      assert length(position.piece_placement.squares) == 10
    end

    test "single square board" do
      assert {:ok, position} = Parser.parse("1 / C/c")

      assert length(position.piece_placement.squares) == 1
      assert length(hd(position.piece_placement.squares)) == 1
    end
  end

  # =============================================================================
  # Valid FEEN Strings - Starting Positions
  # =============================================================================

  describe "parse/1 with starting positions" do
    test "Chess starting position" do
      input = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"
      assert {:ok, position} = Parser.parse(input)

      # First rank should have 8 pieces
      first_rank = hd(position.piece_placement.squares)
      pieces = Enum.filter(first_rank, &(&1 != nil))
      assert length(pieces) == 8
    end

    test "Shogi starting position" do
      input = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      assert {:ok, position} = Parser.parse(input)

      assert position.style_turn.active.style == :S
      assert length(position.piece_placement.squares) == 9
    end

    test "Xiangqi starting position" do
      input = "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
      assert {:ok, position} = Parser.parse(input)

      assert position.style_turn.active.style == :X
      assert length(position.piece_placement.squares) == 10
    end

    test "Makruk starting position" do
      input = "rnsmk^snr/8/pppppppp/8/8/PPPPPPPP/8/RNSK^MSNR / M/m"
      assert {:ok, position} = Parser.parse(input)

      assert position.style_turn.active.style == :M
    end
  end

  # =============================================================================
  # Valid FEEN Strings - Hands
  # =============================================================================

  describe "parse/1 with hands" do
    test "pieces in first hand only" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 2P/ C/c")

      assert length(position.hands.first) == 2
      assert position.hands.second == []
    end

    test "pieces in second hand only" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 /2p C/c")

      assert position.hands.first == []
      assert length(position.hands.second) == 2
    end

    test "pieces in both hands" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 3PB/2p C/c")

      assert length(position.hands.first) == 4  # 3P + 1B
      assert length(position.hands.second) == 2
    end

    test "complex hand with various pieces" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 3P2BNR/pbs C/c")

      first_hand = position.hands.first
      assert length(first_hand) == 7  # 3P + 2B + N + R

      second_hand = position.hands.second
      assert length(second_hand) == 3
    end
  end

  # =============================================================================
  # Valid FEEN Strings - EPIN Modifiers
  # =============================================================================

  describe "parse/1 with EPIN modifiers" do
    test "enhanced pieces" do
      assert {:ok, position} = Parser.parse("+R7/8/8/8/8/8/8/8 / C/c")

      first_square = hd(hd(position.piece_placement.squares))
      assert %Epin{} = first_square
      assert first_square.pin.state == :enhanced
    end

    test "diminished pieces" do
      assert {:ok, position} = Parser.parse("-B7/8/8/8/8/8/8/8 / C/c")

      first_square = hd(hd(position.piece_placement.squares))
      assert first_square.pin.state == :diminished
    end

    test "terminal pieces" do
      assert {:ok, position} = Parser.parse("K^7/8/8/8/8/8/8/8 / C/c")

      first_square = hd(hd(position.piece_placement.squares))
      assert first_square.pin.terminal == true
    end

    test "derived pieces" do
      assert {:ok, position} = Parser.parse("P'7/8/8/8/8/8/8/8 / C/c")

      first_square = hd(hd(position.piece_placement.squares))
      assert first_square.derived == true
    end

    test "fully modified piece (+K^')" do
      assert {:ok, position} = Parser.parse("+K^'7/8/8/8/8/8/8/8 / C/m")

      first_square = hd(hd(position.piece_placement.squares))
      assert first_square.pin.state == :enhanced
      assert first_square.pin.terminal == true
      assert first_square.derived == true
    end
  end

  # =============================================================================
  # Valid FEEN Strings - Cross-Style
  # =============================================================================

  describe "parse/1 with cross-style games" do
    test "Chess vs Makruk" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / C/m")

      assert position.style_turn.active.style == :C
      assert position.style_turn.inactive.style == :M
    end

    test "Shogi vs Xiangqi" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / S/x")

      assert position.style_turn.active.style == :S
      assert position.style_turn.inactive.style == :X
    end

    test "second player active in cross-style" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / m/C")

      assert position.style_turn.active.side == :second
      assert position.style_turn.active.style == :M
    end
  end

  # =============================================================================
  # Valid FEEN Strings - Multi-Dimensional Boards
  # =============================================================================

  describe "parse/1 with multi-dimensional boards" do
    test "3D board with double separators" do
      assert {:ok, position} = Parser.parse("5//5/5//5 / R/r")

      # 4 segments with separators [2, 1, 2]
      assert length(position.piece_placement.squares) == 4
      assert position.piece_placement.separators == [2, 1, 2]
    end

    test "1D board" do
      assert {:ok, position} = Parser.parse("k^+p4+PK^ / C/c")

      assert length(position.piece_placement.squares) == 1
      assert length(hd(position.piece_placement.squares)) == 8
    end

    test "irregular board shape" do
      assert {:ok, position} = Parser.parse("rkr/pp/PPPP / G/g")

      squares = position.piece_placement.squares
      assert length(Enum.at(squares, 0)) == 3  # rkr
      assert length(Enum.at(squares, 1)) == 2  # pp
      assert length(Enum.at(squares, 2)) == 4  # PPPP
    end
  end

  # =============================================================================
  # Invalid FEEN Strings - Whitespace Errors
  # =============================================================================

  describe "parse/1 with whitespace errors" do
    test "leading space" do
      assert {:error, msg} = Parser.parse(" 8/8/8/8/8/8/8/8 / C/c")
      assert msg =~ "leading or trailing whitespace"
    end

    test "trailing space" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / C/c ")
      assert msg =~ "leading or trailing whitespace"
    end

    test "leading tab" do
      assert {:error, msg} = Parser.parse("\t8/8/8/8/8/8/8/8 / C/c")
      assert msg =~ "leading or trailing whitespace"
    end

    test "trailing tab" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / C/c\t")
      assert msg =~ "leading or trailing whitespace"
    end

    test "carriage return" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / C/c\r")
      assert msg =~ "line breaks" or msg =~ "whitespace"
    end

    test "newline" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8\n/ C/c")
      assert msg =~ "line breaks"
    end

    test "CRLF" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8\r\n/ C/c")
      assert msg =~ "line breaks"
    end

    test "newline in middle" do
      assert {:error, msg} = Parser.parse("8/8/8/8\n/8/8/8/8 / C/c")
      assert msg =~ "line breaks"
    end
  end

  # =============================================================================
  # Invalid FEEN Strings - ASCII Errors
  # =============================================================================

  describe "parse/1 with non-ASCII characters" do
    test "Unicode letter in piece placement" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/é / C/c")
      assert msg =~ "ASCII"
    end

    test "Unicode in hands" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 é/ C/c")
      assert msg =~ "ASCII"
    end

    test "Unicode in style-turn" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / Ç/c")
      assert msg =~ "ASCII"
    end

    test "emoji" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / ♔/c")
      assert msg =~ "ASCII"
    end

    test "Japanese character" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / 王/c")
      assert msg =~ "ASCII"
    end
  end

  # =============================================================================
  # Invalid FEEN Strings - Field Count Errors
  # =============================================================================

  describe "parse/1 with wrong field count" do
    test "only one field" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8")
      assert msg =~ "expected exactly 3 fields"
      assert msg =~ "got 1"
    end

    test "only two fields" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 /")
      assert msg =~ "expected exactly 3 fields"
      assert msg =~ "got 2"
    end

    test "four fields" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / C/c extra")
      assert msg =~ "expected exactly 3 fields"
      assert msg =~ "got 4"
    end

    test "empty string" do
      assert {:error, msg} = Parser.parse("")
      assert msg =~ "expected exactly 3 fields"
    end

    test "only spaces" do
      assert {:error, msg} = Parser.parse("   ")
      assert msg =~ "whitespace" or msg =~ "expected exactly 3 fields"
    end

    test "double space between fields" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8  / C/c")
      assert msg =~ "expected exactly 3 fields"
    end
  end

  # =============================================================================
  # Invalid FEEN Strings - Piece Placement Errors
  # =============================================================================

  describe "parse/1 with piece placement errors" do
    test "leading slash" do
      assert {:error, msg} = Parser.parse("/8/8/8/8/8/8/8/8 / C/c")
      assert msg =~ "must not start with /"
    end

    test "trailing slash" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8/ / C/c")
      assert msg =~ "must not end with /"
    end

    test "invalid character in piece placement" do
      assert {:error, msg} = Parser.parse("8/8/8/8/@/8/8/8 / C/c")
      assert msg =~ "unexpected character" or msg =~ "Invalid piece placement"
    end

    test "zero as empty count" do
      assert {:error, msg} = Parser.parse("0/8/8/8/8/8/8/8 / C/c")
      assert msg =~ "empty count" or msg =~ "Invalid"
    end

    test "leading zeros in empty count" do
      assert {:error, msg} = Parser.parse("08/8/8/8/8/8/8/8 / C/c")
      assert msg =~ "leading zeros"
    end

    test "invalid EPIN token order" do
      assert {:error, msg} = Parser.parse("K^+7/8/8/8/8/8/8/8 / C/c")
      assert msg =~ "unexpected character" or msg =~ "Invalid"
    end
  end

  # =============================================================================
  # Invalid FEEN Strings - Hands Errors
  # =============================================================================

  describe "parse/1 with hands errors" do
    test "missing hands delimiter" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 P C/c")
      assert msg =~ "delimiter" or msg =~ "Invalid"
    end

    test "multiple hands delimiters" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 P/B/N C/c")
      assert msg =~ "delimiter"
    end

    test "count of 1 in hands" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 1P/ C/c")
      assert msg =~ "must be >= 2"
    end

    test "leading zeros in hand count" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 02P/ C/c")
      assert msg =~ "leading zeros"
    end

    test "invalid character in hands" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 P@/ C/c")
      assert msg =~ "unexpected character"
    end
  end

  # =============================================================================
  # Invalid FEEN Strings - Style-Turn Errors
  # =============================================================================

  describe "parse/1 with style-turn errors" do
    test "missing style-turn delimiter" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / Cc")
      assert msg =~ "delimiter"
    end

    test "same case styles" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / C/C")
      assert msg =~ "opposite case"
    end

    test "both lowercase" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / c/c")
      assert msg =~ "opposite case"
    end

    test "invalid style token (digit)" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / 1/c")
      assert msg =~ "invalid"
    end

    test "invalid style token (multiple letters)" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / CC/c")
      assert msg =~ "invalid"
    end

    test "empty active style" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / /c")
      assert msg =~ "invalid"
    end

    test "empty inactive style" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / C/")
      assert msg =~ "invalid"
    end
  end

  # =============================================================================
  # Return Type Validation
  # =============================================================================

  describe "parse/1 return type" do
    test "returns Feen struct on success" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")
      assert %Feen{} = position
    end

    test "piece_placement has correct structure" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")

      assert is_map(position.piece_placement)
      assert Map.has_key?(position.piece_placement, :squares)
      assert Map.has_key?(position.piece_placement, :separators)
      assert is_list(position.piece_placement.squares)
      assert is_list(position.piece_placement.separators)
    end

    test "hands has correct structure" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")

      assert is_map(position.hands)
      assert Map.has_key?(position.hands, :first)
      assert Map.has_key?(position.hands, :second)
      assert is_list(position.hands.first)
      assert is_list(position.hands.second)
    end

    test "style_turn has correct structure" do
      assert {:ok, position} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")

      assert is_map(position.style_turn)
      assert Map.has_key?(position.style_turn, :active)
      assert Map.has_key?(position.style_turn, :inactive)
      assert %Sin{} = position.style_turn.active
      assert %Sin{} = position.style_turn.inactive
    end

    test "returns error tuple on failure" do
      assert {:error, reason} = Parser.parse("invalid")
      assert is_binary(reason)
    end
  end

  # =============================================================================
  # Round-Trip Tests
  # =============================================================================

  describe "round-trip (parse -> dump -> parse)" do
    test "empty board preserves structure" do
      input = "8/8/8/8/8/8/8/8 / C/c"
      assert {:ok, position1} = Parser.parse(input)

      output = Feen.to_string(position1)
      assert {:ok, position2} = Parser.parse(output)

      assert position1 == position2
    end

    test "Chess starting position" do
      input = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"
      assert {:ok, position1} = Parser.parse(input)

      output = Feen.to_string(position1)
      assert {:ok, position2} = Parser.parse(output)

      assert position1 == position2
    end

    test "position with hands" do
      input = "8/8/8/8/8/8/8/8 3P2B/2p C/c"
      assert {:ok, position1} = Parser.parse(input)

      output = Feen.to_string(position1)
      assert {:ok, position2} = Parser.parse(output)

      assert position1 == position2
    end

    test "cross-style game" do
      input = "8/8/8/8/8/8/8/8 / C/m"
      assert {:ok, position1} = Parser.parse(input)

      output = Feen.to_string(position1)
      assert {:ok, position2} = Parser.parse(output)

      assert position1 == position2
    end
  end

  # =============================================================================
  # Spec Compliance
  # =============================================================================

  describe "FEEN spec compliance" do
    @tag :spec_compliance
    test "§6.1: rejects leading whitespace" do
      assert {:error, _} = Parser.parse(" 8/8/8/8/8/8/8/8 / C/c")
      assert {:error, _} = Parser.parse("\t8/8/8/8/8/8/8/8 / C/c")
    end

    @tag :spec_compliance
    test "§6.1: rejects trailing whitespace" do
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/c ")
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/c\t")
    end

    @tag :spec_compliance
    test "§6.1: rejects line breaks anywhere" do
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8\n/ C/c")
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 /\nC/c")
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/c\n")
      assert {:error, _} = Parser.parse("8/8/8/8\r/8/8/8/8 / C/c")
    end

    @tag :spec_compliance
    test "§6.1: requires exactly two space separators" do
      # One space
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 /C/c")
      # Three fields is what we need
      assert {:ok, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")
    end

    @tag :spec_compliance
    test "§6.2: rejects non-ASCII" do
      assert {:error, msg} = Parser.parse("8/8/8/8/8/8/8/8 / Ç/c")
      assert msg =~ "ASCII"
    end

    @tag :spec_compliance
    test "§7.2: piece placement must not start with /" do
      assert {:error, _} = Parser.parse("/8/8/8/8/8/8/8 / C/c")
    end

    @tag :spec_compliance
    test "§7.2: piece placement must not end with /" do
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/ / C/c")
    end

    @tag :spec_compliance
    test "§8: hands delimiter always present" do
      # No delimiter should fail
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 P C/c")
      # Empty hands with delimiter should pass
      assert {:ok, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")
    end

    @tag :spec_compliance
    test "§9.3: style-turn tokens must be opposite case" do
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/C")
      assert {:error, _} = Parser.parse("8/8/8/8/8/8/8/8 / c/c")
      assert {:ok, _} = Parser.parse("8/8/8/8/8/8/8/8 / C/c")
      assert {:ok, _} = Parser.parse("8/8/8/8/8/8/8/8 / c/C")
    end
  end

  # =============================================================================
  # Edge Cases
  # =============================================================================

  describe "edge cases" do
    test "minimal valid FEEN" do
      assert {:ok, _} = Parser.parse("1 / A/a")
    end

    test "all 26 styles work" do
      for letter <- ?A..?Z do
        upper = <<letter::utf8>>
        lower = <<(letter + 32)::utf8>>
        input = "8/8/8/8/8/8/8/8 / #{upper}/#{lower}"

        assert {:ok, _} = Parser.parse(input), "Failed for style #{upper}"
      end
    end

    test "very long board" do
      # 100 segments
      segments = List.duplicate("9", 100) |> Enum.join("/")
      input = "#{segments} / C/c"

      assert {:ok, position} = Parser.parse(input)
      assert length(position.piece_placement.squares) == 100
    end

    test "board with many pieces in a row" do
      # 26 pieces (A-Z) in one segment
      pieces = ?A..?Z |> Enum.map(&<<&1::utf8>>) |> Enum.join()
      input = "#{pieces} / C/c"

      assert {:ok, position} = Parser.parse(input)
      first_segment = hd(position.piece_placement.squares)
      assert length(first_segment) == 26
    end

    test "maximum modifiers on one piece" do
      # +K^' has all modifiers
      input = "+K^'7/8/8/8/8/8/8/8 / C/m"

      assert {:ok, position} = Parser.parse(input)
      piece = hd(hd(position.piece_placement.squares))
      assert piece.pin.state == :enhanced
      assert piece.pin.terminal == true
      assert piece.derived == true
    end
  end
end
