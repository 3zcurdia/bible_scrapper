# AGENTS.md

## Commands

- `mix test` — run tests (minimal, mostly doctests)
- `mix credo` — lint
- `mix format` — format code (uses Styler plugin, not default formatter)
- No dialyzer/typecheck configured

## Architecture

- Pure Elixir library (no Phoenix, no OTP app supervision tree)
- Scrapes biblegateway.com using `req` (HTTP) + `floki` (HTML parsing)
- Entry points: `BibleScrapper.scrape_and_save_json!/2` and `scrape_and_save_markdown!/2`
- Book lists (OT/NT/Apocrypha) with chapter counts are module attributes in `lib/bible_scrapper.ex`
- Scraping is concurrent via `Task.async_stream` at book and chapter level
- Output goes to `data/` directory (JSON or markdown per book)

## Conventions

- Tool versions managed by `mise` (see `mise.toml`): Elixir 1.20+, Erlang 29
- Formatter uses `Styler` plugin — run `mix format` before committing
- Credo has `UnsafeToAtom` enabled — avoid `String.to_atom/1` on dynamic input; use `String.to_existing_atom/1`
