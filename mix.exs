defmodule BibleScrapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :bible_scrapper,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A Bible webscraper that scrapes the Bible and saves it to a JSON file.",
      package: [
        maintainers: ["Luis Ezcurdia"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/3zcurdia/bible_scrapper"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, "~> 0.5.16"},
      {:floki, "~> 0.38.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
