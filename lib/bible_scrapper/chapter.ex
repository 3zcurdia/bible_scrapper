defmodule BibleScrapper.Chapter do
  @moduledoc """
  It scrapes a Bible chapter from the Bible Gateway website.
  """

  alias BibleScrapper.Crossref
  alias BibleScrapper.Footnote
  alias BibleScrapper.Verse

  @spec scrape(Floki.html_tree(), integer(), Keyword.t()) :: map()
  def scrape(document, chapter, options \\ []) do
    passage = Floki.find(document, ".passage-content")
    titles = passage |> Floki.find("h3") |> Floki.text()

    crossrefs = scrape_crossrefs(passage)
    footnotes = scrape_footnotes(passage)

    verses =
      passage
      |> Floki.find("p span.text")
      |> Enum.map(&Verse.scrape/1)
      |> Enum.map(&build_verse(&1, footnotes, crossrefs, options))

    %{
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

  defp build_verse(verse, footnotes, crossrefs, options) do
    new_content =
      if Keyword.get(options, :verse_content_object, false) do
        Enum.map(verse.content, fn content ->
          content
          |> Map.put(:crossrefs, Enum.flat_map(content.crossrefs, fn key -> crossrefs[key] end))
          |> Map.put(:footnotes, Enum.map(content.footnotes, fn key -> footnotes[key] end))
        end)
      else
        verse.content
        |> Enum.map(fn content ->
          content.text

          crossrefs = Enum.flat_map(content.crossrefs, fn key -> crossrefs[key] end)
          footnotes = Enum.map(content.footnotes, fn key -> footnotes[key] end)

          crossrefs_txt =
            if Enum.empty?(crossrefs), do: "", else: " [Crossrefs: #{Enum.join(crossrefs, ", ")}]"

          footnotes_txt =
            if Enum.empty?(footnotes), do: "", else: " (Footnotes: #{Enum.join(footnotes, ", ")})"

          content.text <> crossrefs_txt <> footnotes_txt
        end)
        |> Enum.join(" ")
      end

    Map.put(verse, :content, new_content)
  end
end
