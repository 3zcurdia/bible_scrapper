defmodule BibleScrapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :bible_scrapper,
      version: "0.2.0",
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

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.6.2"},
      {:floki, "~> 0.38.0"},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.40.3", only: :dev, runtime: false}
    ]
  end
end
