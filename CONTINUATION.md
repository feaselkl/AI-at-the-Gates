# Continuation Context

## Current Objective
Revise the "AI at the Gates" pre-con (first delivered June 2026, Scenic City Summit) for its next delivery,
**Day of Data Portland, Friday 2026-11-06, still 6.5 hours, co-presented with Jonathan Stewart**:
1. Update content with new information / better approaches.
2. Make the slides and slide text stop reading as AI-generated.
3. Decide whether the pre-con needs structural changes.
Audience: DBAs and database developers with little to no AI background.

## Learning outcomes (Kevin, 2026-11-01) - the spine for any restructure
1. Attendees aren't afraid of vector data: what it is and how it works.
2. They can work with vector data in SQL Server and have what they need to stand up a PoC/pilot in their own environment.
3. They know how to work with modern agentic solutions and what to expect, good and bad.
4. They understand RAG and can put together a basic RAG solution.
5. (Revised same day; on-prem dropped because Kevin can't demo it) They can convince leadership of what's
   possible AND temper expectations: AI agents won't replace the data team.
Scope: everything is on the table, including rebuilding whole sections, if the result is a significant improvement.

## Session Summary
2026-11-01: Review-only session. Extracted text + notes from both decks, rendered the master deck to
thumbnails, read all demo code, and re-verified the fast-moving SQL Server / SSMS facts against
Microsoft Learn. No slide or demo edits yet.

## Decisions Made
- Any section can change; Kevin works out details with Jonathan afterward. Jonathan owns the deck
  generator (`build_deck.py`, not in this repo), so we hand him an updated pptx plus change notes.
- June feedback: positive overall, but too much content ("brains melting" by end of day). No formal evals.
- Master deck is `slides/scenic-city-aigates-precon.pptx` (123 slides, already contains 5.3 RAG).
  `slides/scenic-city-aigates-precon_plus_5_3.pptx` (stale side branch) deleted 2026-11-01.

## Work Completed
- 2026-11-01 review: findings delivered in chat (content updates, demo bugs, AI-feel diagnosis, structural proposals).
- 2026-11-01 factual pass (uncommitted):
  - Deck: 34 text/notes corrections across slides 18-90 plus footer renumbering on 108-123; cleared the
    "generated using python-pptx" metadata tag. Every change is listed in `slides/deck-changes-2026-11.md` for Jonathan.
  - Demos/docs: block4 README + 10/20/30/40 headers (GA status, TOP_N deprecation, int PK, MAXDOP known issue,
    accurate embed-scope comment); block5 file-name references, `make_load_sql.py` output path (was writing the
    old `load_docs.sql`), PREVIEW_FEATURES comment; root/block1/infra READMEs (dead `outlines/` links, Block 5 row).
- 2026-11-01 round 2 (uncommitted):
  - `20_generate_embeddings.sql`: violation loops rewritten as keyset batches over OBJECTID with TRY/CATCH + THROW;
    whitespace-only text skipped and counted. Tested in the container against Harrier on a scratch table
    (25/25 embedded, blank/NULL skipped, broken endpoint stops on first batch). Scratch objects dropped.
  - block5 tsql: real Foundry resource name, deployment names, and master-key password replaced with placeholders.
    The resource name is still in git history (no API key was ever committed).
  - Slide 3 notes: Durham corrected to Raleigh.
  - `slides/cut-list-portland.md`: draft cut list, 16 slides (123 to 107). Superseded by the rebuild spec and deleted 2026-11-01.
- 2026-11-01 round 3 (uncommitted): Kevin approved a full rebuild for Friday around the five outcomes.
  - `slides/portland-rebuild-design.md`: slide-by-slide spec for Jonathan. New order: 0 Opening, 1 How models
    work, 2 Vectors without fear, 3 Vectors in SQL Server (pilot), lunch, 4 RAG, 5 Agents good/bad, 6 Talking to
    leadership. Thread = "how does the model get your context" (vectors, RAG, MCP, agents). Running "ledger"
    (Worked / Broke) filled at each demo, cashed in at the close as the evidence for outcome 5.
    123 - 37 cut - 3 merged + 16 new = 99 slides; every slide accounted for (script-checked).
  - New `src/demo/block4/50_recall_check.sql`: recall@10 of VECTOR_SEARCH vs exact VECTOR_DISTANCE over 25
    sample rows (no endpoint) + one typed question side by side. Tested: recall 0.97, worst 0.70; pest
    question 8/10 overlap. Reports id_recall (INTERSECT) and tie_recall (duplicate comments tie).
  - New `src/demo/block5/tsql/04_eval.sql`: test questions with known source docs; reports rank of expected
    doc, in top-k, best doc/distance. Tested on a scratch DB with Harrier standing in for Foundry: 6/6 at
    rank 1; Kafka out-of-scope best distance 0.595 vs 0.344-0.540 for real questions. Needs a Foundry run.
  - block4/block5 READMEs list the new scripts. Scratch DB dropped, container stopped again.
- 2026-11-01 round 4: Kevin decided Jonathan leads sections 5 and 6; Kevin presents the SSMS piece (5.19, after the perf-triage demo 5.18)
  live or from screenshots depending on time.
  - New `src/demo/block4/ssms-agent/`: README (beats, prompts, screenshot shot list, verify-in-rehearsal list),
    10_constitution.sql (CopilotReader WITHOUT LOGIN, SELECT on 3 tables, column DENY on Inspector/InspectedBy,
    CONSTITUTION.md with agentExecuteAsUser + house rules incl. critical = Priority/Priority Foundation),
    20_prove_it.sql (EXECUTE AS checks), 90_reset.sql. SQL tested in the container (rerunnable, reset clean);
    Copilot itself untested (needs SSMS on the Azure VM + a restored WakeCountyFood, ~1.5 GB).
  - Learned: extended property values are sql_variant, max 7,500 bytes; NVARCHAR(MAX) variable fails (Msg 206).
  - Screenshots can't be produced here (no Windows/SSMS); Kevin captures them in rehearsal.
- 2026-11-01 round 6: cleanup for handoff. Deleted the superseded cut list and the `_plus_5_3` side deck, added
  `slides/README.md` (reading order for Jonathan), dropped decided items from spec section 11, committed on
  local branch `portland-2026-rebuild`. CONTINUATION.md stays untracked (working notes).
- 2026-11-01 round 5: Kevin asked for a full cleanup (notes, references, everything).
  - `slides/portland-slide-text.md`: every slide in the new order (99 + optional 5.19a) with exact visible-text
    edits (each quoted string script-verified against the current deck) and complete new speaker notes;
    31 rehearsal checks collected at the end. Written by 4 parallel subagents from a shared brief
    (scratchpad cleanup-brief.md), then merged and reviewed.
  - Section 5 reordered: 5.17 tuning slide (old 88), 5.18 perf triage as sa (old 89), 5.19 SSMS Agent mode (the
    fix), 5.19a screenshots. Mid-section break after 5.12. Dividers: CHAPTER ONE..SIX.
  - Q&A slide Q.02 -> "Running a vector or RAG pilot"; thank-you slide gets the repo URL.
  - Demo READMEs re-pointed to the new numbering; root README maps block folders to deck sections.
  - CORRECTION: blank-text failure is empty strings only (see Current State); script header, spec, and slide text fixed.

## Current State
- `outlines/` was deleted in commit 8c5ebc0; the pptx is now the only source of slide content.
- Demo container state (found 2026-11-01): only 2,000 of ~310k violation comments are embedded (OBJECTID <= 5752),
  and both vector indexes exist, so FoodInspectionViolation is read-only. Re-embedding needs the index dropped first.
- Blank-text finding (CORRECTED 2026-11-01): an EMPTY string (N'') makes AI_GENERATE_EMBEDDINGS raise Msg 31744 and
  fail the statement (the whole batch). Whitespace-only text (N' ', N'  ', tab) embeds fine. The data has no empty strings;
  OBJECTID 97455 (two spaces) embeds without error. The earlier "whitespace fails" claim came from a scratch test row
  and was wrong. The script still skips both (an empty-text vector is noise).
- Vector-indexed table UPDATE fails with Msg 42231 "Data modification statement failed because table '...' has a
  vector index on it." (tested 2026-11-01).
- Demos: block1 (browser + Ollama), block3 (prompt makeover), block4 (vector scripts + perf-triage),
  block5 (RAG, T-SQL + Python, Microsoft Foundry).

## Verified facts (Microsoft Learn, 2026-11-01)
- SQL Server 2025: AI_GENERATE_EMBEDDINGS and CREATE EXTERNAL MODEL are GA (preview FAQ says so explicitly).
  Only half-precision vectors, JARO_WINKLER_*, vector index / CREATE VECTOR INDEX / VECTOR_SEARCH need PREVIEW_FEATURES.
- SQL Server 2025 still ships the *earlier* vector index version: read-only table, post-filter only, TOP_N,
  clustered PK on an int column required. Latest version (DML, iterative filtering, optimizer-chosen ANN/kNN,
  quantization, sys.dm_db_vector_indexes) is GA in Azure SQL DB, Fabric SQL DB, MI Always-up-to-date.
- VECTOR_SEARCH TOP_N is deprecated in favor of SELECT TOP (N) WITH APPROXIMATE (latest index version only).
- Known issue: MAXDOP on CREATE VECTOR INDEX / VECTOR_SEARCH is ignored in SQL Server 2025.
- Vector indexes: no partitioning, not replicated to subscribers, no DacPac (BACPAC OK from DacFx 170.5.96).
- ALLOW_STALE_VECTOR_INDEX exists but is Azure SQL DB / Fabric only.
- SSMS 22.2 added Copilot completions; SSMS 22.7 added Agent mode (default READ_ONLY), MCP servers, agent skills,
  CONSTITUTION.md / AGENTS.md as extended properties, agentExecuteAsUser (EXECUTE AS, needs IMPERSONATE),
  ADMX policy to disable Agent mode, MCP server allow list.
- Microsoft SQL MCP Server = Data API builder 1.7+/2.0; config-driven, RBAC, intentionally no NL2SQL.
- Azure OpenAI: v1 API path (/openai/v1/...), Responses API recommended for new apps; GPT-5-series reasoning
  models do not accept temperature / top_p.
- AI_GENERATE_EMBEDDINGS / CREATE EXTERNAL MODEL accept PARAMETERS sql_rest_options.retry_count (0-10).

## Next Steps
1. Kevin reviews branch `portland-2026-rebuild` (local, three commits, not pushed); push it and open a PR for Jonathan.
   `slides/README.md` is Jonathan's reading order.
2. Open items: spec section 11 and the "All checks" list at the end of the slide-text file.
   Open items: spec section 11 and the "All checks" list at the end of the slide-text file.
3. Kevin rehearses the SSMS demo on the Azure VM and captures the 8 screenshots.
4. Jonathan rebuilds the deck from the spec by Friday 2026-11-06; Kevin runs 04_eval.sql + 03_rag.sql against
   Foundry and fills the [fill] ledger rows in rehearsal.
5. De-AI pass: done in `portland-slide-text.md` (writing rules in spec section 9). After the rebuild, spot-check the generated deck against it.

## Important References
- Deck text dump script: python-pptx in a scratch venv (`python-pptx 1.0.2`).
- Microsoft Learn pages: create-vector-index-transact-sql, vector-search-transact-sql, preview-features-faq,
  sql-server-2025-known-issues (all view=sql-server-ver17); ssms/github-copilot/agent-mode, execution-context.

## Open Questions / Blockers
- How much restructuring is realistic before Friday vs. after Portland?

## Failed Approaches
- The June "deslop" pass (0 em-dashes, 0 ASCII arrows) targeted punctuation, not the actual tells
  (template uniformity, aphorism footers, presenter directions printed on slides, unrendered image ideas).

## Notes for Next Session
Kevin owns 1.1-1.4, 3.x, 4, 5.3; Jonathan drafted 1.5, 2.x, 5.1/5.2, 6 and the first cut of 5.3.
