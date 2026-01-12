defmodule BibleScrapper.Chapter do
  @moduledoc """
  It scrapes a Bible chapter from the Bible Gateway website.
  """

  alias BibleScrapper.Crossref
  alias BibleScrapper.Footnote
  alias BibleScrapper.Verse

  @spec scrape(Floki.html_tree(), binary(), integer()) :: map()
  def scrape(document, book, chapter) do
    passage = Floki.find(document, ".passage-content")
    titles = passage |> Floki.find("h3") |> Floki.text()

    crossrefs = scrape_crossrefs(passage)
    footnotes = scrape_footnotes(passage)

    verses =
      passage
      |> Floki.find("p span.text")
      |> Enum.map(&Verse.scrape/1)
      |> Enum.map(&build_verse(&1, footnotes, crossrefs))

    %{
      book: book,
      chapter: chapter,
      titles: titles,
      verses: verses
    }
  end

  defp scrape_footnotes(doc) do
    doc
    |> Floki.find("div.footnotes ol li")
    |> Footnote.scrape()
  end

  defp scrape_crossrefs(doc) do
    doc
    |> Floki.find("div.crossrefs ol li")
    |> Crossref.scrape()
  end

  defp build_verse(verse, footnotes, crossrefs) do
    new_content =
      Enum.map(verse.content, fn content ->
        content
        |> Map.put(:crossrefs, Enum.flat_map(content.crossrefs, fn key -> crossrefs[key] end))
        |> Map.put(:footnotes, Enum.map(content.footnotes, fn key -> footnotes[key] end))
      end)

    Map.put(verse, :content, new_content)
  end
end
