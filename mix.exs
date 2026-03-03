defmodule Sashite.Feen.MixProject do
  use Mix.Project

  @version "2.0.0"
  @source_url "https://github.com/sashite/feen.ex"

  def project do
    [
      app: :sashite_feen,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Documentation
      name: "Sashite.Feen",
      source_url: @source_url,
      homepage_url: "https://sashite.dev/specs/feen/",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:qi, "~> 3.0"},
      {:sashite_epin, "~> 1.2"},
      {:sashite_sin, "~> 3.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    FEEN (Field Expression Encoding Notation) implementation for Elixir.
    A rule-agnostic position encoding for two-player, turn-based board games
    built on the Sashité Game Protocol.
    """
  end

  defp package do
    [
      name: "sashite_feen",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://sashite.dev/specs/feen/1.0.0/",
        "Documentation" => "https://hexdocs.pm/sashite_feen"
      },
      maintainers: ["Cyril Kato"]
    ]
  end
end
