defmodule BibleScrapper.VerseTest do
  use ExUnit.Case, async: true

  alias BibleScrapper.Verse

  describe "scrape/1" do
    test "extracts verse number and text content" do
      span =
        {"span", [{"class", "text"}],
         [
           {"span", [{"class", "versenum"}], ["3"]},
           "For God so loved the world"
         ]}

      result = Verse.scrape(span)
      assert result.verse == 3

      assert result.content == [
               %{text: "3", footnotes: [], crossrefs: []},
               %{text: "For God so loved the world", footnotes: [], crossrefs: []}
             ]
    end

    test "defaults verse number to 1 when versenum is missing" do
      span =
        {"span", [{"class", "text"}],
         [
           "In the beginning God created the heavens and the earth."
         ]}

      result = Verse.scrape(span)
      assert result.verse == 1
    end

    test "skips chapternum span" do
      span =
        {"span", [{"class", "text"}],
         [
           {"span", [{"class", "chapternum"}], ["1"]},
           {"span", [{"class", "versenum"}], ["1"]},
           "In the beginning"
         ]}

      result = Verse.scrape(span)
      assert result.verse == 1

      assert result.content == [
               %{text: "1", footnotes: [], crossrefs: []},
               %{text: "In the beginning", footnotes: [], crossrefs: []}
             ]
    end

    test "attaches footnote references from sup elements" do
      span =
        {"span", [{"class", "text"}],
         [
           {"span", [{"class", "versenum"}], ["5"]},
           "Some text",
           {"sup", [{"data-fn", "#fen-123"}], ["a"]},
           " more text"
         ]}

      result = Verse.scrape(span)
      assert result.verse == 5

      content = result.content
      assert length(content) == 3
      assert Enum.at(content, 0).footnotes == ["fen-123"]
    end

    test "attaches crossref references from sup elements" do
      span =
        {"span", [{"class", "text"}],
         [
           {"span", [{"class", "versenum"}], ["16"]},
           "For God so loved",
           {"sup", [{"data-cr", "#cen-456"}], ["b"]},
           " the world"
         ]}

      result = Verse.scrape(span)
      assert result.verse == 16

      content = result.content
      assert length(content) == 3
      assert Enum.at(content, 0).crossrefs == ["cen-456"]
    end

    test "handles multiple footnotes and crossrefs" do
      span =
        {"span", [{"class", "text"}],
         [
           {"span", [{"class", "versenum"}], ["1"]},
           "Text here",
           {"sup", [{"data-fn", "#fen-1"}], ["a"]},
           {"sup", [{"data-cr", "#cen-1"}], ["b"]},
           " more text",
           {"sup", [{"data-fn", "#fen-2"}], ["c"]}
         ]}

      result = Verse.scrape(span)
      content = result.content
      assert length(content) >= 2
    end

    test "normalizes non-breaking spaces" do
      span =
        {"span", [{"class", "text"}],
         [
           {"span", [{"class", "versenum"}], ["1"]},
           "Text\u00A0with\u00A0non-breaking\u00A0spaces"
         ]}

      result = Verse.scrape(span)
      assert Enum.at(result.content, 1).text == "Text with non-breaking spaces"
    end
  end

  describe "parse_num/1" do
    test "extracts number from versenum span" do
      span =
        {"span", [{"class", "text"}], [{"span", [{"class", "versenum"}], ["42"]}, "text"]}

      assert Verse.parse_num(span) == 42
    end

    test "returns 1 when versenum is empty" do
      span =
        {"span", [{"class", "text"}], [{"span", [{"class", "versenum"}], [""]}, "text"]}

      assert Verse.parse_num(span) == 1
    end

    test "returns 1 when versenum is absent" do
      span = {"span", [{"class", "text"}], ["just text"]}
      assert Verse.parse_num(span) == 1
    end

    test "extracts number stripping non-digit chars" do
      span =
        {"span", [{"class", "text"}], [{"span", [{"class", "versenum"}], ["v7"]}, "text"]}

      assert Verse.parse_num(span) == 7
    end
  end
end
