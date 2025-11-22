defmodule BibleScrapper do
  @moduledoc """
  Documentation for `BibleScrapper`.
  """

  alias BibleScrapper.Crossref
  alias BibleScrapper.Footnote
  alias BibleScrapper.Verse

  @old_testament %{
    "Genesis" => 50,
    "Exodus" => 40,
    "Leviticus" => 27,
    "Numbers" => 36,
    "Deuteronomy" => 34,
    "Joshua" => 24,
    "Judges" => 21,
    "Ruth" => 4,
    "1 Samuel" => 31,
    "2 Samuel" => 24,
    "1 Kings" => 22,
    "2 Kings" => 25,
    "1 Chronicles" => 29,
    "2 Chronicles" => 36,
    "Ezra" => 10,
    "Nehemiah" => 13,
    "Esther" => 10,
    "Job" => 42,
    "Psalm" => 150,
    "Proverbs" => 31,
    "Ecclesiastes" => 12,
    "Song of Songs" => 8,
    "Isaiah" => 66,
    "Jeremiah" => 52,
    "Lamentations" => 5,
    "Ezekiel" => 48,
    "Daniel" => 12,
    "Hosea" => 14,
    "Joel" => 3,
    "Amos" => 9,
    "Obadiah" => 1,
    "Jonah" => 4,
    "Micah" => 7,
    "Nahum" => 3,
    "Habakkuk" => 3,
    "Zephaniah" => 3,
    "Haggai" => 2,
    "Zechariah" => 14,
    "Malachi" => 4
  }

  @new_testament %{
    "Matthew" => 28,
    "Mark" => 16,
    "Luke" => 24,
    "John" => 21,
    "Acts" => 28,
    "Romans" => 16,
    "1 Corinthians" => 16,
    "2 Corinthians" => 13,
    "Galatians" => 6,
    "Ephesians" => 6,
    "Philippians" => 4,
    "Colossians" => 4,
    "1 Thessalonians" => 5,
    "2 Thessalonians" => 3,
    "1 Timothy" => 6,
    "2 Timothy" => 4,
    "Titus" => 3,
    "Philemon" => 1,
    "Hebrews" => 13,
    "James" => 5,
    "1 Peter" => 5,
    "2 Peter" => 3,
    "1 John" => 5,
    "2 John" => 1,
    "3 John" => 1,
    "Jude" => 1,
    "Revelation" => 22
  }

  @apocrypha %{
    "Tobit" => 14,
    "Judith" => 16,
    "Greek Esther" => 10,
    "Wisdom of Solomon" => 19,
    "Sirach" => 51,
    "Baruch" => 5,
    "Letter of Jeremiah" => 1,
    "Prayer of Azariah" => 1,
    "Susanna" => 1,
    "Bel and the Dragon" => 1,
    "1 Maccabees" => 16,
    "2 Maccabees" => 15,
    "1 Esdras" => 9,
    "Prayer of Manasseh" => 1,
    "Psalm 151" => 1,
    "3 Maccabees" => 7,
    "2 Esdras" => 16,
    "4 Maccabees" => 18
  }

  @biblegateway_base_url "https://www.biblegateway.com/passage/"

  @doc """
    Returns the URL for a Bible passage on BibleGateway.com.

    ## Examples

        iex> BibleScrapper.bible_gateway_url("John", 3)
        "https://www.biblegateway.com/passage/?search=John+3&version=NRSVUE"

        iex> BibleScrapper.bible_gateway_url("John", 3, "ESV")
        "https://www.biblegateway.com/passage/?search=John+3&version=ESV"

  """
  def bible_gateway_url(book, chapter, version \\ "NRSVUE") do
    "#{@biblegateway_base_url}?search=#{URI.encode("#{book} #{chapter}")}&version=#{URI.encode_www_form(version)}"
  end

  def books do
    @old_testament
    |> Map.merge(@new_testament)
    |> Map.merge(@apocrypha)
  end

  def scrape(version \\ "NRSVUE") do
    books()
    |> Map.keys()
    |> Task.async_stream(&scrape_book(&1, version))
    |> Enum.map(fn {:ok, book} -> book end)
  end

  def save!(bible, path) do
    json = Jason.encode!(bible)

    File.write(path, json)
  end

  def scrape_book(book, version \\ "NRSVUE") do
    chapters = Map.fetch!(books(), book)

    1..chapters
    |> Task.async_stream(&scrape_chapter(book, &1, version))
    |> Enum.map(fn {:ok, chapter} -> chapter end)
  end

  def scrape_chapter(book, chapter, version \\ "NRSVUE") do
    document =
      bible_gateway_url(book, chapter, version)
      |> Req.get!()
      |> Map.get(:body)
      |> Floki.parse_document!()

    passage = Floki.find(document, ".passage-content")
    titles = Floki.find(passage, "h3") |> Floki.text()

    crossrefs =
      passage
      |> Floki.find("div.crossrefs ol li")
      |> Crossref.scrape()

    footnotes =
      passage
      |> Floki.find("div.footnotes ol li")
      |> Footnote.scrape()

    verses =
      passage
      |> Floki.find("p span.text")
      |> Enum.map(&Verse.scrape/1)
      |> Enum.map(fn verse ->
        new_content =
          verse.content
          |> Enum.map(fn content ->
            content
            |> Map.put(:crossrefs, Enum.flat_map(content.crossrefs, fn key -> crossrefs[key] end))
            |> Map.put(:footnotes, Enum.map(content.footnotes, fn key -> footnotes[key] end))
          end)

        Map.put(verse, :content, new_content)
      end)

    %{
      book: book,
      chapter: chapter,
      titles: titles,
      verses: verses
    }
  end
end
