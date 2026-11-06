# Slides

`scenic-city-aigates-precon.pptx` is the deck as delivered at Scenic City Summit in June 2026,
plus the factual fixes listed in `deck-changes-2026-11.md`. The deck is built by Jonathan's
generator, which isn't in this repo, so the Markdown files here are inputs to the next build
rather than edits to the pptx.

## Portland rebuild (Day of Data Portland, 2026-11-06)

Read in this order:

1. **`deck-changes-2026-11.md`**: factual corrections already made in the pptx (GA versus
   preview status, the vector index limits in SQL Server 2025, notes copied onto the wrong
   slide). Port these into the generator source first, or a rebuild puts the old text back.
2. **`portland-rebuild-design.md`**: the new running order built around the five learning
   outcomes. It covers what's cut, merged, and new, the "ledger" thread, the time budget, and
   the writing rules. Section 10 is left to the builder; section 11 lists what's still open.
3. **`portland-slide-text.md`**: each slide in the new order, with the exact visible-text edits
   and complete speaker notes. The checks to confirm in rehearsal are listed at the end.

Demo changes that go with the rebuild are under `src/demo/`. The root README maps the demo
folders to the new deck sections. New since June:

- `src/demo/block4/50_recall_check.sql`: recall of approximate vector search against exact search.
- `src/demo/block5/tsql/04_eval.sql`: does RAG retrieval find the right document?
- `src/demo/block4/ssms-agent/`: GitHub Copilot Agent mode in SSMS with its own
  low-privilege identity and house rules (slide 5.19), live or from screenshots.
