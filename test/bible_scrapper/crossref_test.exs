defmodule BibleScrapper.CrossrefTest do
  use ExUnit.Case, async: true

  alias BibleScrapper.Crossref

  describe "scrape/1" do
    test "extracts crossref id and refs from valid li nodes" do
      nodes = [
        {"li", [{"id", "cen-12345"}],
         [
           {"a", [{"class", "crossref-link"}, {"data-bibleref", "John 3:16"}], ["ref"]}
         ]}
      ]

      assert Crossref.scrape(nodes) == %{"cen-12345" => ["John 3:16"]}
    end

    test "splits multiple comma-separated refs" do
      nodes = [
        {"li", [{"id", "cen-1"}],
         [
           {"a", [{"class", "crossref-link"}, {"data-bibleref", "John 3:16, Romans 8:28, Psalm 23:1"}], ["refs"]}
         ]}
      ]

      result = Crossref.scrape(nodes)
      assert result == %{"cen-1" => ["John 3:16", "Romans 8:28", "Psalm 23:1"]}
    end

    test "extracts multiple crossrefs" do
      nodes = [
        {"li", [{"id", "cen-1"}], [{"a", [{"class", "crossref-link"}, {"data-bibleref", "Gen 1:1"}], ["ref"]}]},
        {"li", [{"id", "cen-2"}], [{"a", [{"class", "crossref-link"}, {"data-bibleref", "Matt 5:3"}], ["ref"]}]}
      ]

      result = Crossref.scrape(nodes)
      assert result["cen-1"] == ["Gen 1:1"]
      assert result["cen-2"] == ["Matt 5:3"]
    end

    test "skips li nodes without id" do
      nodes = [
        {"li", [], [{"a", [{"class", "crossref-link"}, {"data-bibleref", "John 3:16"}], ["ref"]}]}
      ]

      assert Crossref.scrape(nodes) == %{}
    end

    test "skips li nodes without crossref-link anchor" do
      nodes = [
        {"li", [{"id", "cen-1"}], [{"a", [{"class", "other-link"}, {"data-bibleref", "John 3:16"}], ["ref"]}]}
      ]

      assert Crossref.scrape(nodes) == %{}
    end

    test "skips li nodes without data-bibleref attribute" do
      nodes = [
        {"li", [{"id", "cen-1"}], [{"a", [{"class", "crossref-link"}], ["ref"]}]}
      ]

      assert Crossref.scrape(nodes) == %{}
    end

    test "skips non-li nodes" do
      nodes = [
        {"div", [{"id", "cen-1"}], [{"a", [{"class", "crossref-link"}, {"data-bibleref", "John 3:16"}], ["ref"]}]}
      ]

      assert Crossref.scrape(nodes) == %{}
    end

    test "returns empty map for empty list" do
      assert Crossref.scrape([]) == %{}
    end

    test "finds crossref-link nested inside li" do
      nodes = [
        {"li", [{"id", "cen-1"}],
         [
           {"span", [],
            [
              {"a", [{"class", "crossref-link"}, {"data-bibleref", "Isa 53:5"}], ["ref"]}
            ]}
         ]}
      ]

      assert Crossref.scrape(nodes) == %{"cen-1" => ["Isa 53:5"]}
    end
  end
end
