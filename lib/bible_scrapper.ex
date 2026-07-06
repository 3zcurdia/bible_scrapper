defmodule BibleScrapper do
  @moduledoc """
  Documentation for `BibleScrapper`.
  """

  alias BibleScrapper.Chapter

  require Logger

  @default_bible_version "NRSVUE"
  @default_receive_timeout 30_000

  @old_testament %{
    "genesis" => 50,
    "exodus" => 40,
    "leviticus" => 27,
    "numbers" => 36,
    "deuteronomy" => 34,
    "joshua" => 24,
    "judges" => 21,
    "ruth" => 4,
    "1 samuel" => 31,
    "2 samuel" => 24,
    "1 kings" => 22,
    "2 kings" => 25,
    "1 chronicles" => 29,
    "2 chronicles" => 36,
    "ezra" => 10,
    "nehemiah" => 13,
    "esther" => 10,
    "job" => 42,
    "psalm" => 150,
    "proverbs" => 31,
    "ecclesiastes" => 12,
    "song of songs" => 8,
    "isaiah" => 66,
    "jeremiah" => 52,
    "lamentations" => 5,
    "ezekiel" => 48,
    "daniel" => 12,
    "hosea" => 14,
    "joel" => 3,
    "amos" => 9,
    "obadiah" => 1,
    "jonah" => 4,
    "micah" => 7,
    "nahum" => 3,
    "habakkuk" => 3,
    "zephaniah" => 3,
    "haggai" => 2,
    "zechariah" => 14,
    "malachi" => 4
  }

  @new_testament %{
    "matthew" => 28,
    "mark" => 16,
    "luke" => 24,
    "john" => 21,
    "acts" => 28,
    "romans" => 16,
    "1 corinthians" => 16,
    "2 corinthians" => 13,
    "galatians" => 6,
    "ephesians" => 6,
    "philippians" => 4,
    "colossians" => 4,
    "1 thessalonians" => 5,
    "2 thessalonians" => 3,
    "1 timothy" => 6,
    "2 timothy" => 4,
    "titus" => 3,
    "philemon" => 1,
    "hebrews" => 13,
    "james" => 5,
    "1 peter" => 5,
    "2 peter" => 3,
    "1 john" => 5,
    "2 john" => 1,
    "3 john" => 1,
    "jude" => 1,
    "revelation" => 22
  }

  @apocrypha %{
    "tobit" => 14,
    "judith" => 16,
    "greek esther" => 10,
    "wisdom of solomon" => 19,
    "sirach" => 51,
    "baruch" => 5,
    "letter of jeremiah" => 1,
    "prayer of azariah" => 1,
    "susanna" => 1,
    "bel and the dragon" => 1,
    "1 maccabees" => 16,
    "2 maccabees" => 15,
    "1 esdras" => 9,
    "prayer of manasseh" => 1,
    "psalm 151" => 1,
    "3 maccabees" => 7,
    "2 esdras" => 16,
    "4 maccabees" => 18
  }

  defp books(with_apocrypha) do
    bible = Map.merge(@old_testament, @new_testament)

    if with_apocrypha do
      Map.merge(bible, @apocrypha)
    else
      bible
    end
  end

  @spec scrape_and_save_markdown!(String.t(), Keyword.t()) :: :ok | {:error, File.posix()}
  def scrape_and_save_markdown!(version \\ @default_bible_version, options \\ []) do
    version
    |> scrape(Keyword.put(options, :verse_content_object, false))
    |> save_markdown!(Path.join("data", String.downcase(version)))
  end

  defp save_markdown!(json_content, path) do
    File.mkdir_p!(path)

    json_content
    |> Task.async_stream(fn {book, chapters} ->
      book_underscore = String.replace(book, " ", "_")
      markdown = "# #{book}\n\n#{to_markdown_chapters(chapters)}"
      File.write!(Path.join(path, "#{book_underscore}.md"), markdown)
    end)
    |> Stream.run()
  end

  defp to_markdown_chapters(chapters) do
    chapters
    |> Enum.map(& &1.chapter)
    |> Enum.sort()
    |> Enum.map_join("\n\n", fn chapter_num ->
      chapter = Enum.find(chapters, &(&1.chapter == chapter_num))
      titles = chapter["titles"]
      titles_md = if not is_nil(titles) and String.trim(titles) != "", do: "### #{titles}", else: ""

      """
      ## Chapter #{chapter_num}
      #{titles_md}

      #{to_markdown_verses(chapter[:verses])}

      """
    end)
  end

  defp to_markdown_verses(verses) do
    verses
    |> Enum.map(& &1.verse)
    |> Enum.sort()
    |> Enum.map_join("\n", fn verse_num ->
      verse = Enum.find(verses, &(&1.verse == verse_num))
      "#{verse_num}: #{verse[:content]}"
    end)
  end

  @spec scrape_and_save_json!(String.t(), Keyword.t()) :: :ok | {:error, File.posix()}
  def scrape_and_save_json!(version \\ @default_bible_version, options \\ []) do
    version
    |> scrape(options)
    |> Jason.encode!()
    |> then(&File.write(Path.join("data", "#{String.downcase(version)}.json"), &1))
  end

  @spec scrape(String.t(), Keyword.t()) :: map()
  def scrape(version, options \\ []) do
    options
    |> Keyword.get(:with_apocrypha, false)
    |> books()
    |> Task.async_stream(&scrape_book(&1, version, options), timeout: @default_receive_timeout)
    |> Stream.flat_map(fn
      {:ok, %{name: book, chapters: chapters}} ->
        [{book, chapters}]

      {:ok, invalid} ->
        Logger.warning("Invalid book structure: #{inspect(invalid)}")
        []

      {:exit, reason} ->
        Logger.error("Task failed: #{inspect(reason)}")
        []
    end)
    |> Map.new()
  end

  def scrape_book({book, chapters_num}, version, options \\ []) do
    chapters =
      1..chapters_num
      |> Task.async_stream(&scrape_chapter(book, &1, version, options),
        timeout: @default_receive_timeout
      )
      |> Enum.map(fn {:ok, chapter} -> chapter end)

    %{name: book, chapters: chapters}
  end

  defp scrape_chapter(book, chapter, version, options) do
    book
    |> bible_gateway_chapter_url(chapter, version)
    |> Req.get!(receive_timeout: @default_receive_timeout)
    |> Map.get(:body)
    |> Floki.parse_document!()
    |> Chapter.scrape(chapter, options)
  end

  @doc """
    Returns the URL for a Bible passage on BibleGateway.com.

    ## Examples

        iex> BibleScrapper.bible_gateway_chapter_url("John", 3)
        "https://www.biblegateway.com/passage/?search=John+3&version=NRSVUE"

        iex> BibleScrapper.bible_gateway_chapter_url("John", 3, "ESV")
        "https://www.biblegateway.com/passage/?search=John+3&version=ESV"

  """
  def bible_gateway_chapter_url(book, chapter, version) do
    "https://www.biblegateway.com/passage/?search=#{URI.encode("#{book} #{chapter}")}&version=#{URI.encode_www_form(version)}"
  end
end
