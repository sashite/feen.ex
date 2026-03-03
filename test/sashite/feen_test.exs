defmodule Sashite.FeenTest do
  use ExUnit.Case, async: true

  # ===========================================================================
  # max_string_length/0
  # ===========================================================================

  describe "max_string_length/0" do
    test "returns 4096" do
      assert Sashite.Feen.max_string_length() == 4096
    end

    test "returns a positive integer" do
      value = Sashite.Feen.max_string_length()
      assert is_integer(value)
      assert value > 0
    end
  end

  # ===========================================================================
  # parse/1 and valid?/1 consistency -- valid inputs
  # ===========================================================================

  describe "parse/1 and valid?/1 agree on valid inputs" do
    @valid_cases [
      {"8/8/8/8/8/8/8/8 / C/c", "empty chess board"},
      {"-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c", "chess"},
      {"lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s", "shogi"},
      {"rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x", "xiangqi"},
      {"k^ / S/s", "minimal 1D"},
      {"1 / G/g", "minimal 1D empty"},
      {"k^+p4+PK^ / C/c", "1D mixed"},
      {"ab/cd//AB/CD / G/g", "3D 2x2x2"},
      {"3/3/3//3/3/3 / G/g", "3D empty"},
      {"8/8/8/8/8/8/8/8 3P2B/3p2b C/c", "hands with multiplicities"},
      {"8/8/8/8/8/8/8/8 / c/C", "second player active"},
      {"7K^/8 P/ C/c", "one-sided hand"},
      {"8/8 +P/ C/c", "enhanced piece in hand"},
      {"8/8 -P/ C/c", "diminished piece in hand"},
      {"8/8 P^/ C/c", "terminal piece in hand"},
      {"8/8 +P^/ C/c", "enhanced terminal in hand"}
    ]

    for {feen, label} <- @valid_cases do
      @feen feen
      @label label

      test "both accept #{@label}" do
        assert {:ok, _} = Sashite.Feen.parse(@feen)
        assert Sashite.Feen.valid?(@feen)
      end
    end
  end

  # ===========================================================================
  # parse/1 and valid?/1 consistency -- invalid inputs
  # ===========================================================================

  describe "parse/1 and valid?/1 agree on invalid inputs" do
    @invalid_cases [
      {"", "empty string"},
      {"invalid", "single field"},
      {"a b c d", "four fields"},
      {" / C/c", "empty placement"},
      {"44/8 / C/c", "empty count exceeding rank width"},
      {"08/8 / C/c", "leading zero in empty count"},
      {"3/2 / C/c", "irregular board"},
      {"8/8 PP/ C/c", "non-aggregated hand"},
      {"8/8/8/8/8/8/8/8 2P3B/ C/c", "non-canonical hand order"},
      {"8/8 / C/D", "same-case styles"},
      {"8/8 / c/d", "same-case styles lowercase"},
      {"8/8 / 1/c", "non-letter style token"},
      {"8/8 / Cc", "missing style slash"},
      {"K^k^ 2K^/2k^ S/s", "too many pieces"},
      {"256 / C/c", "dimension size exceeds limit"},
      {"8/8 / CC/c", "multi-character style token"}
    ]

    for {feen, label} <- @invalid_cases do
      @feen feen
      @label label

      test "both reject #{@label}" do
        assert {:error, _} = Sashite.Feen.parse(@feen)
        refute Sashite.Feen.valid?(@feen)
      end
    end
  end

  # ===========================================================================
  # parse/1 and valid?/1 consistency -- non-string inputs
  # ===========================================================================

  describe "parse/1 and valid?/1 agree on non-string inputs" do
    @non_string_cases [nil, 42, :chess, [], %{}, {:ok, "data"}]

    for input <- @non_string_cases do
      @input input

      test "both reject #{inspect(@input)}" do
        assert {:error, :not_a_string} = Sashite.Feen.parse(@input)
        refute Sashite.Feen.valid?(@input)
      end
    end
  end

  # ===========================================================================
  # dump/1 output is always accepted by parse/1 and valid?/1
  # ===========================================================================

  describe "dump/1 output accepted by parse/1 and valid?/1" do
    @dump_input_cases [
      "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c",
      "lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s",
      "ab/cd//AB/CD / G/g",
      "8/8/8/8/8/8/8/8 3P2B/3p2b C/c",
      "8/8/8/8/8/8/8/8 / c/C",
      "k^ / S/s",
      "1 / G/g",
      "8/8 +P/ C/c",
      "8/8 -P/ C/c",
      "8/8 P^/ C/c"
    ]

    for feen <- @dump_input_cases do
      @feen feen

      test "dump output for #{inspect(@feen)} is valid" do
        dumped = @feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
        assert Sashite.Feen.valid?(dumped)
        assert {:ok, _} = Sashite.Feen.parse(dumped)
      end
    end
  end

  # ===========================================================================
  # dump/1 output length within bounds
  # ===========================================================================

  describe "dump/1 output respects max_string_length" do
    test "chess starting position fits" do
      feen = "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"
      dumped = feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
      assert byte_size(dumped) <= Sashite.Feen.max_string_length()
    end

    test "raumschach starting position fits" do
      feen =
        "-rnk^n-r/+p+p+p+p+p/5/5/5" <>
          "//buqbu/+p+p+p+p+p/5/5/5" <>
          "//5/5/5/5/5" <>
          "//5/5/5/+P+P+P+P+P/BUQBU" <>
          "//5/5/5/+P+P+P+P+P/-RNK^N-R / R/r"

      dumped = feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
      assert byte_size(dumped) <= Sashite.Feen.max_string_length()
    end
  end
end
