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

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.16"},
      {:floki, "~> 0.38.0"},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.39.1", only: :dev, runtime: false}
    ]
  end
end
