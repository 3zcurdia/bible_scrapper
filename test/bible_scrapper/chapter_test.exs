defmodule BibleScrapper.ChapterTest do
  use ExUnit.Case, async: true

  alias BibleScrapper.Chapter

  @minimal_passage """
  <div class="passage-content">
    <h3>Genesis 1</h3>
    <p>
      <span class="text">
        <span class="chapternum">1</span>
        <span class="versenum">1</span>
        In the beginning God created the heavens and the earth.
      </span>
    </p>
    <p>
      <span class="text">
        <span class="versenum">2</span>
        Now the earth was formless and empty.
      </span>
    </p>
  </div>
  """

  @passage_with_footnotes """
  <div class="passage-content">
    <h3>John 1</h3>
    <p>
      <span class="text">
        <span class="versenum">1</span>
        In the beginning was the Word<sup data-fn="#fen-1">a</sup>
      </span>
    </p>
    <div class="footnotes">
      <ol>
        <li id="fen-1">
          <span class="footnote-text">Or <i>Word</i>; Greek <i>Logos</i></span>
        </li>
      </ol>
    </div>
  </div>
  """

  @passage_with_crossrefs """
  <div class="passage-content">
    <h3>John 3</h3>
    <p>
      <span class="text">
        <span class="versenum">16</span>
        For God so loved the world<sup data-cr="#cen-1">a</sup>
      </span>
    </p>
    <div class="crossrefs">
      <ol>
        <li id="cen-1">
          <a class="crossref-link" data-bibleref="Rom 5:8, 1 John 4:9">refs</a>
        </li>
      </ol>
    </div>
  </div>
  """

  describe "scrape/3" do
    test "extracts chapter number, titles, and verses" do
      doc = Floki.parse_document!(@minimal_passage)
      result = Chapter.scrape(doc, 1)

      assert result.chapter == 1
      assert result.titles == "Genesis 1"
      assert length(result.verses) == 2
    end

    test "verses contain correct verse numbers" do
      doc = Floki.parse_document!(@minimal_passage)
      result = Chapter.scrape(doc, 1)

      assert Enum.at(result.verses, 0).verse == 1
      assert Enum.at(result.verses, 1).verse == 2
    end

    test "default option returns string content" do
      doc = Floki.parse_document!(@minimal_passage)
      result = Chapter.scrape(doc, 1)

      verse = Enum.at(result.verses, 0)
      assert is_binary(verse.content)
      assert verse.content =~ "In the beginning"
    end

    test "verse_content_object: true returns list of maps" do
      doc = Floki.parse_document!(@minimal_passage)
      result = Chapter.scrape(doc, 1, verse_content_object: true)

      verse = Enum.at(result.verses, 0)
      assert is_list(verse.content)
      assert Enum.all?(verse.content, &is_map/1)
      assert Enum.all?(verse.content, &Map.has_key?(&1, :text))
      assert Enum.all?(verse.content, &Map.has_key?(&1, :footnotes))
      assert Enum.all?(verse.content, &Map.has_key?(&1, :crossrefs))
    end

    test "resolves footnotes in verse content" do
      doc = Floki.parse_document!(@passage_with_footnotes)
      result = Chapter.scrape(doc, 1, verse_content_object: true)

      verse = Enum.at(result.verses, 0)

      footnote_values =
        verse.content |> Enum.flat_map(& &1.footnotes) |> Enum.reject(&is_nil/1)

      assert footnote_values != []
      assert Enum.any?(footnote_values, &String.contains?(&1, "Logos"))
    end

    test "resolves crossrefs in verse content" do
      doc = Floki.parse_document!(@passage_with_crossrefs)
      result = Chapter.scrape(doc, 3, verse_content_object: true)

      verse = Enum.at(result.verses, 0)

      crossref_values =
        verse.content |> Enum.flat_map(& &1.crossrefs) |> Enum.reject(&is_nil/1)

      assert crossref_values != []
      assert Enum.any?(crossref_values, &String.contains?(&1, "Rom"))
    end

    test "includes footnotes in string content when verse_content_object is false" do
      doc = Floki.parse_document!(@passage_with_footnotes)
      result = Chapter.scrape(doc, 1)

      verse = Enum.at(result.verses, 0)
      assert verse.content =~ "Footnotes"
    end

    test "includes crossrefs in string content when verse_content_object is false" do
      doc = Floki.parse_document!(@passage_with_crossrefs)
      result = Chapter.scrape(doc, 3)

      verse = Enum.at(result.verses, 0)
      assert verse.content =~ "Crossrefs"
    end

    test "handles empty passage" do
      doc = Floki.parse_document!(~s(<div class="passage-content"></div>))
      result = Chapter.scrape(doc, 1)

      assert result.chapter == 1
      assert result.titles == ""
      assert result.verses == []
    end
  end
end
