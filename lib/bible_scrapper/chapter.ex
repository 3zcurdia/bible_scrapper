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

  # credo:disable-for-lines:25 Credo.Check.Refactor.Nesting
  defp build_verse(verse, footnotes, crossrefs, options) do
    new_content =
      if Keyword.get(options, :verse_content_object, false) do
        Enum.map(verse.content, fn content ->
          content
          |> Map.put(:crossrefs, Enum.flat_map(content.crossrefs, fn key -> crossrefs[key] end))
          |> Map.put(:footnotes, Enum.map(content.footnotes, fn key -> footnotes[key] end))
        end)
      else
        Enum.map_join(
          verse.content,
          " ",
          fn content ->
            crossrefs = Enum.flat_map(content.crossrefs, fn key -> crossrefs[key] end)
            footnotes = Enum.map(content.footnotes, fn key -> footnotes[key] end)
            crossrefs_txt = textify_enum("Crossrefs", crossrefs)
            footnotes_txt = textify_enum("Footnotes", footnotes)

            content.text <> crossrefs_txt <> footnotes_txt
          end
        )
      end

    Map.put(verse, :content, new_content)
  end

  defp textify_enum(key, enum) do
    if Enum.empty?(enum) do
      ""
    else
      " (#{key}: #{Enum.join(enum, ", ")})"
    end
  end
end
