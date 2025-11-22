defmodule BibleScrapper.Verse do
  @moduledoc """
  Scrapes a verse span into structured content segments:
  [
    %{text: "...", footnotes: ["..."], crossrefs: ["..."]}
  ]
  """

  def scrape({"span", _attrs, children} = span) do
    %{
      verse: parse_num(span),
      content: parse_content(children)
    }
  end

  def parse_num(span) do
    span
    |> Floki.find(".versenum")
    |> Floki.text()
    |> String.trim()
    |> case do
      "" ->
        1

      txt ->
        txt
        |> String.replace(~r/[^\d]/, "")
        |> case do
          "" -> 1
          num -> String.to_integer(num)
        end
    end
  end

  defp parse_content(nodes) do
    nodes
    |> do_parse([])
    |> Enum.map(&normalize_segment/1)
    |> Enum.reverse()
  end

  defp do_parse([], acc), do: Enum.reverse(acc)

  defp do_parse([node | rest], acc) do
    cond do
      is_binary(node) ->
        # text node
        text = clean_text(node)
        segment = %{text: text, footnotes: [], crossrefs: []}
        do_parse(rest, add_segment(acc, segment))

      match?({"span", [{"class", "chapternum"} | _], _}, node) ->
        # skip chapter number
        do_parse(rest, acc)

      match?({"sup", _, _}, node) ->
        do_parse(rest, handle_sup(node, acc))

      match?({_, _, _}, node) ->
        {_, _, children} = node
        do_parse(children ++ rest, acc)

      true ->
        do_parse(rest, acc)
    end
  end

  defp handle_sup({"sup", _attrs, _}, []), do: []

  defp handle_sup({"sup", attrs, _}, acc) do
    cond do
      fn_id = get_attr(attrs, "data-fn") ->
        attach_to_last(acc, :footnotes, strip_ref(fn_id))

      cr_id = get_attr(attrs, "data-cr") ->
        attach_to_last(acc, :crossrefs, strip_ref(cr_id))

      true ->
        acc
    end
  end

  defp attach_to_last(acc, key, id) do
    List.update_at(acc, -1, fn seg ->
      Map.update(seg, key, [id], fn lst -> lst ++ [id] end)
    end)
  end

  defp add_segment([], seg), do: [seg]

  defp add_segment(acc, %{text: ""}), do: acc

  defp add_segment([last | rest], %{text: text} = seg) do
    if String.trim(text) == "" do
      [last | rest]
    else
      [seg | [last | rest]]
    end
    |> Enum.reverse()
  end

  # ensure text is trimmed and single spaces
  defp normalize_segment(%{text: t} = seg),
    do: %{seg | text: String.trim(t)}

  defp get_attr(attrs, key),
    do: Enum.find_value(attrs, fn {k, v} -> if k == key, do: v end)

  defp strip_ref("#" <> id), do: id
  defp strip_ref(id), do: id

  defp clean_text(txt),
    do: txt |> String.replace("\u00A0", " ") |> String.replace(~r/\s+/, " ")
end
