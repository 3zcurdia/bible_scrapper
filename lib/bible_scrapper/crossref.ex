defmodule BibleScrapper.Crossref do
  @moduledoc """
  Scrapes <li> elements structured as Floki-like tuples into a map of id => list of Bible refs.
  """

  def scrape(li_nodes) when is_list(li_nodes) do
    li_nodes
    |> Enum.reduce(%{}, fn
      {"li", attrs, children}, acc ->
        id = get_attr(attrs, "id")

        data_bibleref =
          children
          |> find_crossref_data_bibleref()

        case {id, data_bibleref} do
          {nil, _} ->
            acc

          {_, nil} ->
            acc

          {id, refs} ->
            Map.put(acc, id, split_refs(refs))
        end

      _, acc ->
        acc
    end)
  end

  defp get_attr(attrs, key), do: attrs |> Enum.find_value(fn {k, v} -> if k == key, do: v end)

  defp find_crossref_data_bibleref(nodes) do
    Enum.find_value(nodes, fn
      {"a", attrs, _children} ->
        if get_attr(attrs, "class") == "crossref-link" do
          get_attr(attrs, "data-bibleref")
        end

      {_, _, children} when is_list(children) ->
        find_crossref_data_bibleref(children)

      _ ->
        nil
    end)
  end

  defp split_refs(nil), do: []

  defp split_refs(str) do
    str
    |> String.split(~r/,\s*/)
    |> Enum.map(&String.trim/1)
  end
end
