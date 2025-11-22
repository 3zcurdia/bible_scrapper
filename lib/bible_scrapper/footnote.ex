defmodule BibleScrapper.Footnote do
  @moduledoc """
  Scrapes <li> elements containing <span class="footnote-text"> into a map of id => text.
  """

  def scrape(li_nodes) when is_list(li_nodes) do
    Enum.reduce(li_nodes, %{}, fn
      {"li", attrs, children}, acc ->
        id = get_attr(attrs, "id")
        footnote_text = find_footnote_text(children)

        case {id, footnote_text} do
          {nil, _} -> acc
          {_, nil} -> acc
          {id, text} -> Map.put(acc, id, normalize_text(text))
        end

      _, acc ->
        acc
    end)
  end

  # Extract attribute from tag attrs
  defp get_attr(attrs, key), do: attrs |> Enum.find_value(fn {k, v} -> if k == key, do: v end)

  # Recursively find <span class="footnote-text">
  defp find_footnote_text(nodes) do
    Enum.find_value(nodes, fn
      {"span", attrs, children} ->
        if get_attr(attrs, "class") == "footnote-text" do
          flatten_text(children)
        end

      {_, _, children} when is_list(children) ->
        find_footnote_text(children)

      _ ->
        nil
    end)
  end

  # Recursively flatten nested tags into plain text
  defp flatten_text(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(fn
      binary when is_binary(binary) -> binary
      {_, _, children} -> flatten_text(children)
      _ -> ""
    end)
    |> Enum.join()
  end

  defp flatten_text(_), do: ""

  # Normalize whitespace and trim
  defp normalize_text(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
