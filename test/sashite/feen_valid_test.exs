defmodule Sashite.Feen.ValidTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # valid?/1 -- non-binary input (returns false, never raises)
  # ===========================================================================

  describe "valid?/1 non-binary input" do
    test "returns false for nil" do
      refute Sashite.Feen.valid?(nil)
    end

    test "returns false for integer" do
      refute Sashite.Feen.valid?(42)
    end

    test "returns false for atom" do
      refute Sashite.Feen.valid?(:chess)
    end

    test "returns false for list" do
      refute Sashite.Feen.valid?([])
    end

    test "returns false for map" do
      refute Sashite.Feen.valid?(%{})
    end

    test "returns false for tuple" do
      refute Sashite.Feen.valid?({:ok, "data"})
    end
  end

  # ===========================================================================
  # valid?/1 -- size and encoding
  # ===========================================================================

  describe "valid?/1 size and encoding" do
    test "rejects string longer than 4096 bytes" do
      long_board = String.duplicate("1/", 2048) <> "1"
      input = long_board <> " / C/c"
      assert byte_size(input) > 4096
      refute Sashite.Feen.valid?(input)
    end

    test "rejects byte above 127" do
      refute Sashite.Feen.valid?(<<128>> <> " / C/c")
    end

    test "rejects UTF-8 multibyte characters" do
      refute Sashite.Feen.valid?("8/8 / " <> <<0xC3, 0xA9>> <> "/c")
    end
  end

  # ===========================================================================
  # valid?/1 -- field splitting
  # ===========================================================================

  describe "valid?/1 field splitting" do
    test "rejects empty string" do
      refute Sashite.Feen.valid?("")
    end

    test "rejects single field" do
      refute Sashite.Feen.valid?("8/8")
    end

    test "rejects two fields" do
      refute Sashite.Feen.valid?("8/8 /")
    end

    test "rejects four fields" do
      refute Sashite.Feen.valid?("8/8 / C/c extra")
    end
  end

  # ===========================================================================
  # valid?/1 -- piece placement rejections
  # ===========================================================================

  describe "valid?/1 piece placement rejections" do
    test "rejects empty piece placement field" do
      refute Sashite.Feen.valid?(" / C/c")
    end

    test "rejects piece placement starting with separator" do
      refute Sashite.Feen.valid?("/8/8 / C/c")
    end

    test "rejects piece placement ending with separator" do
      refute Sashite.Feen.valid?("8/8/ / C/c")
    end

    test "rejects double slash as dimensional coherence violation" do
      refute Sashite.Feen.valid?("8//8 / C/c")
    end

    test "rejects empty count exceeding rank width" do
      refute Sashite.Feen.valid?("44/8 / C/c")
    end

    test "rejects empty count with leading zero" do
      refute Sashite.Feen.valid?("08/8 / C/c")
    end

    test "rejects empty count of zero" do
      refute Sashite.Feen.valid?("0K^7/8 / C/c")
    end

    test "rejects invalid piece token" do
      refute Sashite.Feen.valid?("8/8/8/8/8/8/8/!!!!!! / C/c")
    end

    test "rejects board not regular" do
      refute Sashite.Feen.valid?("3/2 / C/c")
    end

    test "rejects dimensional coherence violation" do
      refute Sashite.Feen.valid?("ab//cd / G/g")
    end

    test "rejects exceeding max dimensions (4D)" do
      feen_4d = "a/b//c/d" <> "///" <> "e/f//g/h / G/g"
      refute Sashite.Feen.valid?(feen_4d)
    end
  end

  # ===========================================================================
  # valid?/1 -- hands rejections
  # ===========================================================================

  describe "valid?/1 hands rejections" do
    test "rejects hands without slash" do
      refute Sashite.Feen.valid?("8/8 P C/c")
    end

    test "rejects hands with two slashes" do
      refute Sashite.Feen.valid?("8/8 P/B/r C/c")
    end

    test "rejects hand count with leading zero" do
      refute Sashite.Feen.valid?("8/8 02P/ C/c")
    end

    test "rejects hand count of 1" do
      refute Sashite.Feen.valid?("8/8 1P/ C/c")
    end

    test "rejects hand count of 0" do
      refute Sashite.Feen.valid?("8/8 0P/ C/c")
    end

    test "rejects invalid piece token in hand" do
      refute Sashite.Feen.valid?("8/8 !/ C/c")
    end

    test "rejects non-aggregated hand items" do
      refute Sashite.Feen.valid?("8/8 PP/ C/c")
    end

    test "rejects non-canonical hand ordering (count ascending)" do
      refute Sashite.Feen.valid?("8/8/8/8/8/8/8/8 2P3B/ C/c")
    end

    test "rejects non-canonical hand ordering (sort key wrong)" do
      refute Sashite.Feen.valid?("8/8/8/8/8/8/8/8 PB/ C/c")
    end
  end

  # ===========================================================================
  # valid?/1 -- style-turn rejections
  # ===========================================================================

  describe "valid?/1 style-turn rejections" do
    test "rejects style-turn without slash" do
      refute Sashite.Feen.valid?("8/8 / Cc")
    end

    test "rejects style-turn with two slashes" do
      refute Sashite.Feen.valid?("8/8 / C/c/x")
    end

    test "rejects non-letter style token" do
      refute Sashite.Feen.valid?("8/8 / 1/c")
    end

    test "rejects same-case style tokens (both uppercase)" do
      refute Sashite.Feen.valid?("8/8 / C/D")
    end

    test "rejects same-case style tokens (both lowercase)" do
      refute Sashite.Feen.valid?("8/8 / c/d")
    end

    test "rejects multi-character style token" do
      refute Sashite.Feen.valid?("8/8 / CC/c")
    end
  end

  # ===========================================================================
  # valid?/1 -- cardinality rejections
  # ===========================================================================

  describe "valid?/1 cardinality rejections" do
    test "rejects when pieces exceed squares (board + hands)" do
      refute Sashite.Feen.valid?("K^k^ 2K^/2k^ S/s")
    end

    test "rejects when hand pieces alone exceed squares" do
      refute Sashite.Feen.valid?("2/2 10k^/ S/s")
    end
  end

  # ===========================================================================
  # valid?/1 -- dimension size limit rejections
  # ===========================================================================

  describe "valid?/1 dimension size limit rejections" do
    test "rejects 1D board exceeding 255 squares" do
      refute Sashite.Feen.valid?("256 / C/c")
    end

    test "rejects 2D rank width exceeding 255" do
      refute Sashite.Feen.valid?("256/256 / C/c")
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: traditional starting positions
  # ===========================================================================

  describe "valid?/1 traditional starting positions" do
    test "chess" do
      assert Sashite.Feen.valid?(
               "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"
             )
    end

    test "shogi" do
      assert Sashite.Feen.valid?(
               "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
             )
    end

    test "xiangqi" do
      assert Sashite.Feen.valid?(
               "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
             )
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: empty boards
  # ===========================================================================

  describe "valid?/1 empty boards" do
    test "empty 8x8 board" do
      assert Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / C/c")
    end

    test "minimal 1D empty board" do
      assert Sashite.Feen.valid?("1 / G/g")
    end

    test "empty 3D board" do
      assert Sashite.Feen.valid?("3/3/3//3/3/3 / G/g")
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: dimensionality
  # ===========================================================================

  describe "valid?/1 dimensionality" do
    test "1D board" do
      assert Sashite.Feen.valid?("k^+p4+PK^ / C/c")
    end

    test "1D minimal occupied" do
      assert Sashite.Feen.valid?("k^ / S/s")
    end

    test "2D board (standard chess)" do
      assert Sashite.Feen.valid?("8/8 / C/c")
    end

    test "3D board (2x2x2)" do
      assert Sashite.Feen.valid?("ab/cd//AB/CD / G/g")
    end

    test "3D raumschach" do
      feen =
        "-rnk^n-r/+p+p+p+p+p/5/5/5" <>
          "//buqbu/+p+p+p+p+p/5/5/5" <>
          "//5/5/5/5/5" <>
          "//5/5/5/+P+P+P+P+P/BUQBU" <>
          "//5/5/5/+P+P+P+P+P/-RNK^N-R / R/r"

      assert Sashite.Feen.valid?(feen)
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: hands
  # ===========================================================================

  describe "valid?/1 hands" do
    test "empty hands (just slash)" do
      assert Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / C/c")
    end

    test "hands with multiplicities" do
      assert Sashite.Feen.valid?("8/8/8/8/8/8/8/8 3P2B/3p2b C/c")
    end

    test "hands with single pieces" do
      assert Sashite.Feen.valid?(
               "r1bq1b1r/+p+p+p+p1k^+p+p/2n2n2/4p3/4P3/5N2/+P+P+P+P1+P+P+P/-RNBQK^2+R p/B C/c"
             )
    end

    test "hand with one side empty" do
      assert Sashite.Feen.valid?("7K^/8 P/ C/c")
    end

    test "enhanced piece in hand" do
      assert Sashite.Feen.valid?("8/8 +P/ C/c")
    end

    test "diminished piece in hand" do
      assert Sashite.Feen.valid?("8/8 -P/ C/c")
    end

    test "terminal piece in hand" do
      assert Sashite.Feen.valid?("8/8 P^/ C/c")
    end

    test "terminal derived piece in hand" do
      feen = "8/8 P^" <> "'" <> "/ C/c"
      assert Sashite.Feen.valid?(feen)
    end

    test "mixed modified pieces in both hands" do
      assert Sashite.Feen.valid?("8/8/8/8/8/8/8/8 2+P-P/+p C/c")
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: turn
  # ===========================================================================

  describe "valid?/1 turn" do
    test "first player active" do
      assert Sashite.Feen.valid?("8/8 / C/c")
    end

    test "second player active" do
      assert Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / c/C")
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: EPIN modifiers
  # ===========================================================================

  describe "valid?/1 EPIN modifiers" do
    test "enhanced pieces" do
      assert Sashite.Feen.valid?("+R7/8 / C/c")
    end

    test "diminished pieces" do
      assert Sashite.Feen.valid?("-R7/8 / C/c")
    end

    test "terminal pieces" do
      assert Sashite.Feen.valid?("K^7/8 / C/c")
    end

    test "derived pieces" do
      feen = "lnsgk^" <> "'" <> "gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      assert Sashite.Feen.valid?(feen)
    end

    test "all modifiers combined" do
      feen = "+R^" <> "'" <> "7/8 / C/c"
      assert Sashite.Feen.valid?(feen)
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: cross-style
  # ===========================================================================

  describe "valid?/1 cross-style games" do
    test "chess vs makruk" do
      assert Sashite.Feen.valid?("rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/m")
    end
  end

  # ===========================================================================
  # valid?/1 -- acceptance: after opening moves
  # ===========================================================================

  describe "valid?/1 after opening moves" do
    test "chess after 1.e4" do
      assert Sashite.Feen.valid?(
               "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / c/C"
             )
    end

    test "chess after 1.e4 c5 (Sicilian)" do
      assert Sashite.Feen.valid?(
               "-rnbqk^bn-r/+p+p1+p+p+p+p+p/8/2p5/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / C/c"
             )
    end

    test "shogi after 1.P-7f" do
      assert Sashite.Feen.valid?(
               "lnsgk^gsnl/1r5b1/ppppppppp/9/9/2P6/PP1PPPPPP/1B5R1/LNSGK^GSNL / s/S"
             )
    end
  end
end
