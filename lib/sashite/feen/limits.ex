defmodule Sashite.Feen.Limits do
  @moduledoc false

  # Implementation limits for bounded parsing.
  #
  # These constraints enable safe parsing with predictable memory usage
  # while remaining sufficient for all realistic board game positions.
  #
  # All values are exposed as zero-arity functions that inline at compile
  # time via @compile {:inline, ...}, giving callers the same performance
  # as hard-coded literals with the benefit of a single source of truth.

  @compile {:inline, max_string_length: 0, max_dimensions: 0, max_dimension_size: 0}

  @max_string_length 4_096
  @max_dimensions 3
  @max_dimension_size 255

  @doc false
  @spec max_string_length() :: pos_integer()
  def max_string_length, do: @max_string_length

  @doc false
  @spec max_dimensions() :: pos_integer()
  def max_dimensions, do: @max_dimensions

  @doc false
  @spec max_dimension_size() :: pos_integer()
  def max_dimension_size, do: @max_dimension_size
end
