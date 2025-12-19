defmodule Espresso.MixProject do
  use Mix.Project

  def project do
    [
      app: :espresso,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: "A lightweight, macro-based web framework inspired by Express.js",
      deps: deps(),
      description: "A minimal, macro-based web framework inspired by Express.js",
      package: package(),
      name: "Espresso",
      source_url: "https://github.com/pckrishnadas88/espresso"
    ]
  end
  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pckrishnadas88/espresso"},
      maintainers: ["Krishnadas P.C"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"}
    ]
  end
end
