defmodule BibleScrapper.FootnoteTest do
  use ExUnit.Case, async: true

  alias BibleScrapper.Footnote

  describe "scrape/1" do
    test "extracts footnote id and text from valid li nodes" do
      nodes = [
        {"li", [{"id", "fen-12345"}],
         [
           {"span", [{"class", "footnote-text"}], ["Some footnote text"]}
         ]}
      ]

      assert Footnote.scrape(nodes) == %{"fen-12345" => "Some footnote text"}
    end

    test "extracts multiple footnotes" do
      nodes = [
        {"li", [{"id", "fen-1"}], [{"span", [{"class", "footnote-text"}], ["First footnote"]}]},
        {"li", [{"id", "fen-2"}], [{"span", [{"class", "footnote-text"}], ["Second footnote"]}]}
      ]

      result = Footnote.scrape(nodes)
      assert result["fen-1"] == "First footnote"
      assert result["fen-2"] == "Second footnote"
    end

    test "flattens nested tags into plain text" do
      nodes = [
        {"li", [{"id", "fen-1"}],
         [
           {"span", [{"class", "footnote-text"}],
            [
              "Start ",
              {"em", [], ["italic"]},
              " middle ",
              {"strong", [], ["bold"]},
              " end"
            ]}
         ]}
      ]

      assert Footnote.scrape(nodes) == %{"fen-1" => "Start italic middle bold end"}
    end

    test "skips li nodes without id" do
      nodes = [
        {"li", [], [{"span", [{"class", "footnote-text"}], ["No id"]}]}
      ]

      assert Footnote.scrape(nodes) == %{}
    end

    test "skips li nodes without footnote-text span" do
      nodes = [
        {"li", [{"id", "fen-1"}], [{"span", [{"class", "other"}], ["No footnote text"]}]}
      ]

      assert Footnote.scrape(nodes) == %{}
    end

    test "skips non-li nodes" do
      nodes = [
        {"div", [{"id", "fen-1"}], [{"span", [{"class", "footnote-text"}], ["Not a list item"]}]}
      ]

      assert Footnote.scrape(nodes) == %{}
    end

    test "returns empty map for empty list" do
      assert Footnote.scrape([]) == %{}
    end

    test "normalizes whitespace in footnote text" do
      nodes = [
        {"li", [{"id", "fen-1"}], [{"span", [{"class", "footnote-text"}], ["  too   much   space  "]}]}
      ]

      assert Footnote.scrape(nodes) == %{"fen-1" => "too much space"}
    end

    test "finds footnote-text span nested deep inside li" do
      nodes = [
        {"li", [{"id", "fen-1"}],
         [
           {"div", [],
            [
              {"span", [{"class", "footnote-text"}], ["Deeply nested"]}
            ]}
         ]}
      ]

      assert Footnote.scrape(nodes) == %{"fen-1" => "Deeply nested"}
    end
  end
end
