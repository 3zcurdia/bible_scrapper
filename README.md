# BibleScrapper

Simple biblegateway scrapper.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bible_scrapper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bible_scrapper, "~> 0.1.0"}
  ]
end
```

### Usage

```elixir
  BibleScrapper.scrape_and_save!("KJV", "kjv.json")
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/bible_scrapper>.
