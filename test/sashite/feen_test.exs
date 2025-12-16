# test/sashite/feen_test.exs

defmodule Sashite.FeenTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen

  doctest Sashite.Feen

  # ===========================================================================
  # parse/1
  # ===========================================================================

  describe "parse/1" do
    test "parses empty 8x8 board" do
      feen = "8/8/8/8/8/8/8/8 / C/c"

      assert {:ok, position} = Feen.parse(feen)
      assert position.hands.first == []
      assert position.hands.second == []
      assert position.style_turn.active.side == :first
      assert position.style_turn.inactive.side == :second
    end

    test "parses chess starting position" do
      feen = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"

      assert {:ok, position} = Feen.parse(feen)
      assert position.style_turn.active.style == :C
      assert position.style_turn.active.side == :first
    end

    test "parses shogi starting position" do
      feen = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"

      assert {:ok, position} = Feen.parse(feen)
      assert position.style_turn.active.style == :S
      assert position.style_turn.active.side == :first
    end

    test "parses xiangqi starting position" do
      feen = "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"

      assert {:ok, position} = Feen.parse(feen)
      assert position.style_turn.active.style == :X
    end

    test "parses makruk starting position" do
      feen = "rnsmk^snr/8/pppppppp/8/8/PPPPPPPP/8/RNSK^MSNR / M/m"

      assert {:ok, position} = Feen.parse(feen)
      assert position.style_turn.active.style == :M
    end

    test "parses position with pieces in hand" do
      feen = "8/8/8/8/8/8/8/8 2P3B/p C/c"

      assert {:ok, position} = Feen.parse(feen)
      assert length(position.hands.first) == 5
      assert length(position.hands.second) == 1
    end

    test "parses position with second player to move" do
      feen = "8/8/8/8/8/8/8/8 / c/C"

      assert {:ok, position} = Feen.parse(feen)
      assert position.style_turn.active.side == :second
      assert position.style_turn.inactive.side == :first
    end

    test "parses cross-style game" do
      feen = "rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/m"

      assert {:ok, position} = Feen.parse(feen)
      assert position.style_turn.active.style == :C
      assert position.style_turn.inactive.style == :M
    end

    test "parses position with derived pieces" do
      feen = "K'/7 / C/c"

      assert {:ok, position} = Feen.parse(feen)
      [[first_piece | _] | _] = position.piece_placement.squares
      assert first_piece.derived == true
    end

    test "parses position with terminal pieces" do
      feen = "K^/7 / C/c"

      assert {:ok, position} = Feen.parse(feen)
      [[first_piece | _] | _] = position.piece_placement.squares
      assert first_piece.pin.terminal == true
    end

    test "parses position with enhanced pieces" do
      feen = "+K/7 / C/c"

      assert {:ok, position} = Feen.parse(feen)
      [[first_piece | _] | _] = position.piece_placement.squares
      assert first_piece.pin.state == :enhanced
    end

    test "parses position with diminished pieces" do
      feen = "-K/7 / C/c"

      assert {:ok, position} = Feen.parse(feen)
      [[first_piece | _] | _] = position.piece_placement.squares
      assert first_piece.pin.state == :diminished
    end

    test "parses 3D board with double slashes" do
      feen = "8/8//8/8 / C/c"

      assert {:ok, position} = Feen.parse(feen)
      assert length(position.piece_placement.squares) == 4
      # Separators: [1, 2, 1] means single slash, double slash, single slash
      assert position.piece_placement.separators == [1, 2, 1]
    end

    test "returns error for invalid input type" do
      assert {:error, message} = Feen.parse(123)
      assert message =~ "expected a string"
    end

    test "returns error for wrong number of fields" do
      assert {:error, message} = Feen.parse("8/8/8/8/8/8/8/8 C/c")
      assert message =~ "expected exactly 3 fields"
    end

    test "returns error for leading whitespace" do
      assert {:error, message} = Feen.parse(" 8/8/8/8/8/8/8/8 / C/c")
      assert message =~ "leading or trailing whitespace"
    end

    test "returns error for trailing whitespace" do
      assert {:error, message} = Feen.parse("8/8/8/8/8/8/8/8 / C/c ")
      assert message =~ "leading or trailing whitespace"
    end

    test "returns error for line breaks" do
      assert {:error, message} = Feen.parse("8/8/8/8\n8/8/8/8 / C/c")
      assert message =~ "line breaks"
    end

    test "returns error for non-ASCII characters" do
      assert {:error, message} = Feen.parse("8/8/8/8/8/8/8/8 / C/é")
      assert message =~ "ASCII"
    end

    test "returns error for invalid piece placement" do
      assert {:error, message} = Feen.parse("/8/8/8/8/8/8/8 / C/c")
      assert message =~ "piece placement"
    end

    test "returns error for invalid hands" do
      assert {:error, message} = Feen.parse("8/8/8/8/8/8/8/8 P C/c")
      assert message =~ "hands"
    end

    test "returns error for invalid style-turn" do
      assert {:error, message} = Feen.parse("8/8/8/8/8/8/8/8 / C/C")
      assert message =~ "opposite case"
    end
  end

  # ===========================================================================
  # parse!/1
  # ===========================================================================

  describe "parse!/1" do
    test "returns position for valid FEEN" do
      feen = "8/8/8/8/8/8/8/8 / C/c"

      assert %Feen{} = Feen.parse!(feen)
    end

    test "raises ArgumentError for invalid FEEN" do
      assert_raise ArgumentError, ~r/Invalid FEEN/, fn ->
        Feen.parse!("invalid")
      end
    end
  end

  # ===========================================================================
  # valid?/1
  # ===========================================================================

  describe "valid?/1" do
    test "returns true for valid empty board" do
      assert Feen.valid?("8/8/8/8/8/8/8/8 / C/c")
    end

    test "returns true for chess starting position" do
      assert Feen.valid?("+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c")
    end

    test "returns true for shogi starting position" do
      assert Feen.valid?("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")
    end

    test "returns true for position with pieces in hand" do
      assert Feen.valid?("8/8/8/8/8/8/8/8 3P2B/2p C/c")
    end

    test "returns true for cross-style game" do
      assert Feen.valid?("8/8/8/8/8/8/8/8 / M/c")
    end

    test "returns false for invalid string" do
      refute Feen.valid?("invalid")
    end

    test "returns false for non-string input" do
      refute Feen.valid?(123)
      refute Feen.valid?(nil)
      refute Feen.valid?([])
    end

    test "returns false for empty string" do
      refute Feen.valid?("")
    end

    test "returns false for wrong field count" do
      refute Feen.valid?("8/8/8/8/8/8/8/8 C/c")
    end
  end

  # ===========================================================================
  # to_string/1
  # ===========================================================================

  describe "to_string/1" do
    test "serializes empty board" do
      feen = "8/8/8/8/8/8/8/8 / C/c"
      {:ok, position} = Feen.parse(feen)

      assert Feen.to_string(position) == feen
    end

    test "serializes chess starting position" do
      feen = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"
      {:ok, position} = Feen.parse(feen)

      assert Feen.to_string(position) == feen
    end

    test "serializes shogi starting position" do
      feen = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      {:ok, position} = Feen.parse(feen)

      assert Feen.to_string(position) == feen
    end

    test "serializes position with pieces in hand" do
      feen = "8/8/8/8/8/8/8/8 3P2B/p C/c"
      {:ok, position} = Feen.parse(feen)

      assert Feen.to_string(position) == feen
    end

    test "serializes position with second player to move" do
      feen = "8/8/8/8/8/8/8/8 / c/C"
      {:ok, position} = Feen.parse(feen)

      assert Feen.to_string(position) == feen
    end

    test "serializes 3D board with double slashes" do
      feen = "8/8//8/8 / C/c"
      {:ok, position} = Feen.parse(feen)

      assert Feen.to_string(position) == feen
    end

    test "produces canonical hand ordering" do
      # Non-canonical input: pieces not aggregated
      feen = "8/8/8/8/8/8/8/8 PBP/p C/c"
      {:ok, position} = Feen.parse(feen)

      # Should produce canonical output: aggregated and sorted
      assert Feen.to_string(position) == "8/8/8/8/8/8/8/8 2PB/p C/c"
    end
  end

  # ===========================================================================
  # Round-trip tests
  # ===========================================================================

  describe "round-trip" do
    test "parse then to_string preserves canonical FEEN" do
      canonical_feens = [
        "8/8/8/8/8/8/8/8 / C/c",
        "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c",
        "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s",
        "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x",
        "rnsmk^snr/8/pppppppp/8/8/PPPPPPPP/8/RNSK^MSNR / M/m",
        "8/8/8/8/8/8/8/8 3P2B/2p C/c",
        "8/8/8/8/8/8/8/8 / c/C",
        "K^'/7 / C/c",
        "+K^/7 / C/c",
        "-k/7 / C/c"
      ]

      for feen <- canonical_feens do
        {:ok, position} = Feen.parse(feen)
        assert Feen.to_string(position) == feen, "Round-trip failed for: #{feen}"
      end
    end
  end

  # ===========================================================================
  # Protocol implementations
  # ===========================================================================

  describe "String.Chars protocol" do
    test "to_string/1 works via protocol" do
      feen = "8/8/8/8/8/8/8/8 / C/c"
      {:ok, position} = Feen.parse(feen)

      assert "#{position}" == feen
    end
  end

  describe "Inspect protocol" do
    test "inspect shows FEEN representation" do
      feen = "8/8/8/8/8/8/8/8 / C/c"
      {:ok, position} = Feen.parse(feen)

      assert inspect(position) == "#Sashite.Feen<8/8/8/8/8/8/8/8 / C/c>"
    end
  end
end
