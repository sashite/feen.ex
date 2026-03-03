defmodule Sashite.Feen.DumpTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # dump/1 -- round-trip: traditional starting positions
  # ===========================================================================

  describe "dump/1 round-trip traditional positions" do
    test "chess starting position" do
      feen = "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "shogi starting position" do
      feen = "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "xiangqi starting position" do
      feen = "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: empty boards
  # ===========================================================================

  describe "dump/1 round-trip empty boards" do
    test "empty 8x8 board" do
      feen = "8/8/8/8/8/8/8/8 / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "minimal 1D empty board" do
      feen = "1 / G/g"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "empty 3D board" do
      feen = "3/3/3//3/3/3 / G/g"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "empty 2-rank board" do
      feen = "8/8 / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: 1D boards
  # ===========================================================================

  describe "dump/1 round-trip 1D boards" do
    test "minimal 1D occupied" do
      feen = "k^ / S/s"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "1D board with mixed pieces and empties" do
      feen = "k^+p4+PK^ / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: 3D boards
  # ===========================================================================

  describe "dump/1 round-trip 3D boards" do
    test "3D 2x2x2" do
      feen = "ab/cd//AB/CD / G/g"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "raumschach 5x5x5" do
      feen =
        "-rnk^n-r/+p+p+p+p+p/5/5/5" <>
          "//buqbu/+p+p+p+p+p/5/5/5" <>
          "//5/5/5/5/5" <>
          "//5/5/5/+P+P+P+P+P/BUQBU" <>
          "//5/5/5/+P+P+P+P+P/-RNK^N-R / R/r"

      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: hands
  # ===========================================================================

  describe "dump/1 round-trip hands" do
    test "hands with multiplicities" do
      feen = "8/8/8/8/8/8/8/8 3P2B/3p2b C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "hands with single pieces (chess captures)" do
      feen = "r1bq1b1r/+p+p+p+p1k^+p+p/2n2n2/4p3/4P3/5N2/+P+P+P+P1+P+P+P/-RNBQK^2+R p/B C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "one side empty hand" do
      feen = "7K^/8 P/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: turn variations
  # ===========================================================================

  describe "dump/1 round-trip turn" do
    test "first player active" do
      feen = "8/8/8/8/8/8/8/8 / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "second player active" do
      feen = "8/8/8/8/8/8/8/8 / c/C"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: EPIN modifiers
  # ===========================================================================

  describe "dump/1 round-trip EPIN modifiers" do
    test "enhanced pieces" do
      feen = "+R7/8 / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "diminished pieces" do
      feen = "-R7/8 / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "derived pieces" do
      feen = "lnsgk^" <> "'" <> "gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "all modifiers combined" do
      feen = "+R^" <> "'" <> "7/8 / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: after opening moves
  # ===========================================================================

  describe "dump/1 round-trip after opening moves" do
    test "chess after 1.e4" do
      feen = "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / c/C"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "chess Sicilian after 1.e4 c5" do
      feen = "-rnbqk^bn-r/+p+p1+p+p+p+p+p/8/2p5/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: hands with EPIN modifiers
  # ===========================================================================

  describe "dump/1 round-trip hand EPIN modifiers" do
    test "enhanced piece in hand" do
      feen = "8/8 +P/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "diminished piece in hand" do
      feen = "8/8 -P/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "terminal piece in hand" do
      feen = "8/8 P^/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "terminal derived piece in hand" do
      feen = "8/8 P^" <> "\x27" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "derived piece without terminal in hand" do
      feen = "8/8 P" <> "\x27" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "enhanced terminal piece in hand" do
      feen = "8/8 +P^/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "diminished terminal derived piece in hand" do
      feen = "8/8 -P^" <> "\x27" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "lowercase modified pieces in hand" do
      feen = "8/8 /+p C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "mixed modifiers both hands" do
      feen = "8/8/8/8/8/8/8/8 2+P-P/+p C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- round-trip: cross-style
  # ===========================================================================

  describe "dump/1 round-trip cross-style" do
    test "chess vs makruk" do
      feen = "rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/m"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # dump/1 -- Field 1: run-length encoding
  # ===========================================================================

  describe "dump/1 run-length encoding" do
    test "merges consecutive empty squares into single count" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f1 == "8/8/8/8/8/8/8/8"
    end

    test "places empty count between pieces" do
      pos = Sashite.Feen.parse!("k^+p4+PK^ / C/c")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f1 == "k^+p4+PK^"
    end

    test "no empty count when rank is fully occupied" do
      pos = Sashite.Feen.parse!("+P+P+P+P+P+P+P+P/8 / C/c")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      [rank1, _rank2] = String.split(f1, "/")
      refute String.match?(rank1, ~r/\d/)
    end

    test "empty count of 1 for single empty square" do
      pos = Sashite.Feen.parse!("1r5b1/9 / C/c")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      [rank1, _rank2] = String.split(f1, "/")
      assert rank1 == "1r5b1"
    end
  end

  # ===========================================================================
  # dump/1 -- Field 1: separator levels
  # ===========================================================================

  describe "dump/1 separator levels" do
    test "single slash between ranks in 2D" do
      pos = Sashite.Feen.parse!("8/8 / C/c")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f1 == "8/8"
    end

    test "double slash between layers in 3D" do
      pos = Sashite.Feen.parse!("ab/cd//AB/CD / G/g")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f1 == "ab/cd//AB/CD"
    end

    test "no separators in 1D" do
      pos = Sashite.Feen.parse!("k^+p4+PK^ / C/c")
      [f1, _f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      refute String.contains?(f1, "/")
    end
  end

  # ===========================================================================
  # dump/1 -- Field 2: hands serialization
  # ===========================================================================

  describe "dump/1 hands serialization" do
    test "empty hands produce just slash" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f2 == "/"
    end

    test "implicit count 1 for single piece" do
      pos = Sashite.Feen.parse!("7K^/8 P/ C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f2 == "P/"
    end

    test "explicit count for multiplicities" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 3P2B/3p2b C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f2 == "3P2B/3p2b"
    end

    test "one side empty other non-empty" do
      feen = "r1bq1b1r/+p+p+p+p1k^+p+p/2n2n2/4p3/4P3/5N2/+P+P+P+P1+P+P+P/-RNBQK^2+R p/B C/c"
      pos = Sashite.Feen.parse!(feen)
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f2 == "p/B"
    end
  end

  # ===========================================================================
  # dump/1 -- Field 2: canonical hand ordering
  # ===========================================================================

  describe "dump/1 canonical hand ordering" do
    test "higher count comes first (multiplicity descending)" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 3P2B/3p2b C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f2 == "3P2B/3p2b"
    end

    test "alphabetical order when counts equal" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 BP/ C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      [first_hand, _] = String.split(f2, "/")
      assert first_hand == "BP"
    end

    test "uppercase before lowercase for same letter" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 Bb/ C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      [first_hand, _] = String.split(f2, "/")
      assert first_hand == "Bb"
    end

    test "complex ordering: count desc, letter asc, case" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 3P2Bbp/ C/c")
      [_f1, f2, _f3] = String.split(Sashite.Feen.dump(pos), " ")
      [first_hand, _] = String.split(f2, "/")
      assert first_hand == "3P2Bbp"
    end
  end

  # ===========================================================================
  # dump/1 -- Field 3: style-turn
  # ===========================================================================

  describe "dump/1 style-turn" do
    test "active player style comes first" do
      pos = Sashite.Feen.parse!("8/8 / C/c")
      [_f1, _f2, f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f3 == "C/c"
    end

    test "second player active: lowercase leads" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / c/C")
      [_f1, _f2, f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f3 == "c/C"
    end

    test "shogi styles" do
      pos = Sashite.Feen.parse!("1 / S/s")
      [_f1, _f2, f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f3 == "S/s"
    end

    test "cross-style game" do
      pos = Sashite.Feen.parse!("rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/m")
      [_f1, _f2, f3] = String.split(Sashite.Feen.dump(pos), " ")
      assert f3 == "C/m"
    end
  end

  # ===========================================================================
  # dump/1 -- overall format
  # ===========================================================================

  describe "dump/1 overall format" do
    test "three fields separated by single spaces" do
      pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")
      parts = String.split(Sashite.Feen.dump(pos), " ")
      assert length(parts) == 3
    end

    test "no leading or trailing whitespace" do
      pos =
        Sashite.Feen.parse!(
          "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"
        )

      dumped = Sashite.Feen.dump(pos)
      assert dumped == String.trim(dumped)
    end

    test "output is valid FEEN" do
      pos =
        Sashite.Feen.parse!("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")

      assert Sashite.Feen.valid?(Sashite.Feen.dump(pos))
    end

    test "output is pure ASCII" do
      pos =
        Sashite.Feen.parse!("rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x")

      dumped = Sashite.Feen.dump(pos)
      assert dumped == for(<<byte <- dumped>>, byte in 0..127, into: "", do: <<byte>>)
    end
  end

  # ===========================================================================
  # dump/1 -- idempotence
  # ===========================================================================

  describe "dump/1 idempotence" do
    @idempotence_cases [
      "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c",
      "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s",
      "ab/cd//AB/CD / G/g",
      "8/8/8/8/8/8/8/8 3P2B/3p2b C/c",
      "8/8/8/8/8/8/8/8 / c/C",
      "k^ / S/s"
    ]

    for feen <- @idempotence_cases do
      @feen feen

      test "dump(parse(dump(parse(#{inspect(@feen)})))) is stable" do
        pos1 = Sashite.Feen.parse!(@feen)
        dumped1 = Sashite.Feen.dump(pos1)
        pos2 = Sashite.Feen.parse!(dumped1)
        dumped2 = Sashite.Feen.dump(pos2)
        assert dumped1 == dumped2
      end
    end
  end
end
