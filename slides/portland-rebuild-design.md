# Portland rebuild: design

Day of Data Portland, Friday 2026-11-06. Still 6.5 hours, Kevin and Jonathan co-presenting.
Slide numbers in this document are the current master deck
(`slides/scenic-city-aigates-precon.pptx`, 123 slides, with the factual fixes from
`deck-changes-2026-11.md` already applied). The exact on-slide edits and complete speaker
notes for every slide are in `portland-slide-text.md`.

## 0. How this gets built

- Jonathan regenerates the deck with his generator (`build_deck.py`, not in this repo). This
  document and the repo are his inputs.
- **First task:** port the fixes in `deck-changes-2026-11.md` into the generator's source. They
  were made directly in the pptx, so a regeneration without them puts the wrong GA/preview
  statements back on 71 and 72, drops the int primary key requirement from 73, and so on.
  That includes the hidden copied subtitles on 77 and 89.
- Suggested build order (my call, change it if the engine favors another): cuts, moves, and
  merges first; then the visible-text edits on kept slides; then the new slides; then the
  ledger rows marked **[fill]**, which Kevin sends after rehearsal as a short list.

## 1. Why we're rebuilding

June went well, but there was too much material and people were worn out by the end of the
day. The day was also organized by topic area (foundations, tools, prompts, DBA, developer,
build-your-own) instead of by what attendees should leave able to do. Counted against
those goals, RAG had 6 slides and about 30 slides served none of them.

## 2. What attendees leave with (the yardstick for every slide)

1. They aren't afraid of vector data: what it is and how it works.
2. They can work with vector data in SQL Server and have what they need to run a proof of
   concept or pilot in their own shop.
3. They know how to work with today's agentic tools, and what to expect from them, good and bad.
4. They understand RAG and can put together a basic RAG solution.
5. They can make the case to leadership for what's possible, and can push back on
   overblown expectations, such as replacing the data team with agents.

Every slide that stays has to serve at least one of these. Anything that doesn't is cut.

## 3. Goals, non-goals, anti-goals

**Goals**
- Fewer slides than June (about 100, down from 123) with more time on outcomes 2 and 4.
- One thread through the day, so the afternoon builds on the morning instead of starting over.
- Every demo leaves the room with something that worked and something that broke.

**Non-goals**
- On-premises AI as a topic. We can't demonstrate it, so it's dropped. The Block 4 demos
  still happen to run on a local model; mention it in passing, but don't build a section on it.
- New demo infrastructure. Every demo uses what already exists in the repo.

**Anti-goals (a failure even if every slide is correct)**
- The day sounds like DBAs defending their jobs. Outcome 5 has to rest on what the room saw
  happen during the day, not on our opinions.
- The rebuild adds net material. If a new slide goes in, something else comes out.
- The new slides read as AI-generated (see section 9).

## 4. The thread and the ledger

**The thread.** Each section answers the same question one step further: how does the
model get *your* context?

| Section | Answer |
|---|---|
| Vectors | Your data, turned into something a model can search |
| RAG | You find the relevant context and hand it to the model |
| MCP | The model looks it up itself |
| Agents | The model acts on what it finds |

**The ledger.** A running two-column tally, "Worked" and "Broke", filled in by what the room
sees in the demos. It appears at the end of sections 1, 3, 4, and 5, each time with that
section's new rows added and highlighted, and in full in section 6, where it becomes the
evidence for outcome 5. These ledger slides replace the old "takeaways" slides.

Ledger rules:
- Only things that happened on screen today. No industry statistics, no hypotheticals.
- One line per entry, in plain words, with the number where there is one.
- Entries marked **[fill]** depend on how a live demo goes; the presenter confirms them in rehearsal.

The starting rows are listed with each section below.

## 5. Running order and time budget

The minutes assume about 360 minutes of talking once breaks and lunch are out. **[Kevin:
replace with the real schedule.]** Each section lists slides to drop if it runs long.

| # | Section | Outcomes | Min | Slides (approx.) | Lead |
|---|---|---|---|---|---|
| 0 | Opening | all | 10 | 5 | both |
| 1 | How these models work, just enough | 1, 3 | 35 | 11 | Kevin |
| 2 | Vectors without fear | 1 | 40 | 12 | Kevin |
| 3 | Vectors in SQL Server: your pilot | 2 | 80 | 23 | Kevin |
| | *Lunch* | | | | |
| 4 | RAG | 4 | 50 | 11 | Kevin |
| 5 | Agents: the good and the bad | 3 | 100 | 26 | Jonathan; Kevin presents 5.19 (SSMS) |
| 6 | Talking to leadership | 5 | 35 | 11 | Jonathan |

Sections 0 to 4 follow who owned the material in June (Kevin owned 1.1 to 1.4, Block 3,
Block 4, and 5.3). Kevin confirmed Jonathan leads sections 5 and 6. Within section 5, Kevin
presents the SSMS demo (5.19). Whether he also takes the tuning slide and perf-triage demo just
before it (5.17, 5.18), which were his Block 4 material, is **[Kevin + Jonathan]**; the three
work as one block.

Lunch after section 3 puts all the vector material in the morning, while people are fresh,
and the demo-heavy agent section after lunch. A break belongs in the middle of section 5.

### Section 0: Opening (10 min)

| New order | From | Action |
|---|---|---|
| 0.1 | 1 | Keep. Change "SCENIC CITY SUMMIT 2026" to the Portland event name. |
| 0.2 | 2 | Keep. |
| 0.3 | 3 | Keep. |
| 0.4 | new | **What you'll leave with.** See section 8. |
| 0.5 | new | **The ledger.** See section 8. |

### Section 1: How these models work, just enough (35 min)

| New order | From | Action |
|---|---|---|
| 1.0 | 4 | Divider. Retitle "How these models work". |
| 1.1 | 12 | Keep "You don't build models. You own the data they use." It frames the day. |
| 1.2 | 9 | Keep (next-token prediction). |
| 1.3 | 10 | Keep (Guess the Next Word). Its notes are a copy of slide 12's; replace them (see below). |
| 1.4 | 15 | Keep (tokens). |
| 1.5 | 16 | Keep (context window). |
| 1.6 | 17 | Keep (fluent, confident, wrong). |
| 1.7 | 52 | Move here from Block 3 (the overconfident junior). |
| 1.8 | 18 | Keep (the dials). |
| 1.9 | 19 | Keep (temperature demo). |
| 1.10 | new | Ledger, section 1 rows. |

Cut: 5, 6, 7, 8, 11, 13, 14 (the neural network demo). Slide 21 still mentions that an
embedding model is a neural network; that's fine without the demo.
Drop if long: 16.

Notes for 1.3 (my reading of the slide; Kevin to confirm): no model on screen. The room calls
out the next words ("human events"). That's all a model does: predict the likeliest next
token, over and over. The room got it right because it has seen that sentence many times;
so has the model.

Ledger rows (demos only, so slides 10 and 17 don't add rows):
- Worked: at temperature 0, the same prompt gave the same answer.
- Broke: at high temperature, the same prompt gave different answers each run.

### Section 2: Vectors without fear (40 min)

| New order | From | Action |
|---|---|---|
| 2.0 | new divider | "Vectors without fear". |
| 2.1 to 2.10 | 20 to 29 | Keep in order: embeddings, embedding model, similarity, both Projector demos (23, 24), why a data pro should care, how vectors differ from the data you store, the ANN trade-off, three knobs, approximate search you've seen. |
| 2.11 | 31 | Keep (text to tokens to embeddings to similarity to storage). |

Cut: 30. No ledger slide for this section; its rows join section 3's.
Drop if long: 29.

Ledger rows (shown with section 3):
- Worked: violation comments about the same problem clustered together with no keywords in common (slide 24 demo).

### Section 3: Vectors in SQL Server: your pilot (80 min)

| New order | From | Action |
|---|---|---|
| 3.0 | 62 | Divider. Retitle "Vectors in SQL Server". |
| 3.1 | 63 | Keep. |
| 3.2 | 65 | Keep (VECTOR(n) column). |
| 3.3 | 66 | Keep (exact kNN). |
| 3.4 | 67 | Keep (approximate results, recall). |
| 3.5 | 68 | Keep (styles of vector index). |
| 3.6 | 70 | Keep (index or brute force). |
| 3.7 | 71 | Keep (what's in SQL Server 2025). |
| 3.8 | 72 | Keep (the SQL family). |
| 3.9 | 73 | Keep (read-only index). |
| 3.10 | 76 | Keep (in-database vs dedicated store). Add one line for Cosmos DB and one for pgvector, folded in from 74 and 75. |
| 3.11 | 77 | Keep (demo: scripts 10 to 40 in `src/demo/block4/`). |
| 3.12 | new | **Is the index giving the right answers?** See section 8. |
| 3.13 | new | Demo slide for `50_recall_check.sql`. See section 8. |
| 3.14 | 78 | Keep (pure vs hybrid). |
| 3.15 | 79 | Keep (post-filter trap). |
| 3.16 | 80 | Keep (RRF). |
| 3.17 | 82 | Keep (batch vs real-time embedding). |
| 3.18 | 83 | Keep (capacity math). |
| 3.19 | 84 | Keep (build after bulk load). |
| 3.20 | 85 + 86 | Merge into one slide, "Running it: monitoring and backup". Keep the sys.vector_indexes, external-endpoint-dependency, and "vectors back up with the table; the model doesn't" points. |
| 3.21 | 90 | Rebuild as **Your pilot, step by step**. See section 8. |
| 3.22 | new | Ledger, sections 2 and 3 rows. |

Cut: 64, 69, 74, 75, 81, 87. Slides 88 and 89 (AI-assisted tuning and the perf-triage
demo) move to section 5.
Drop if long: 80, then 84.

Ledger rows:
- Worked: "rodent or pest activity in the kitchen" found roach, fly, and mouse comments that
  share none of those words with the question (`40_vector_search.sql`, query B).
- Broke: an empty string doesn't come back as NULL. `SELECT AI_GENERATE_EMBEDDINGS(N'' USE MODEL
  HarrierEmbeddings);` fails with Msg 31744, and inside a batch UPDATE that one row fails the whole
  batch. (Show it live; it takes one line.)
- Broke: once indexed, the table went read-only. Adding rows means drop the index, embed, rebuild.
- Broke: for the pest question, the index's top 10 matched the exact top 10 on 8 of 10 rows.
  Across 25 sample rows, recall was 0.97, and the worst single query was 0.70. (Measured
  2026-11-01 on the demo container: 2,000 embedded comments. Rerun before Friday; the numbers
  change if the embedded set changes.)

### Section 4: RAG (50 min)

| New order | From | Action |
|---|---|---|
| 4.0 | new divider | "RAG". |
| 4.1 | 101 | Rewrite the body. It says "5.2 gave you tools that fetch context", which comes later now. New body: "Section 3 turned your data into vectors. RAG puts them to work: find the passages that answer a question, and hand only those to the model." |
| 4.2 | 102 | Keep (RAG in DBA terms). |
| 4.3 | 103 | Keep (tribal knowledge). |
| 4.4 | 104 | Keep (chunking). |
| 4.5 | 105 | Keep (minimal pipeline). |
| 4.6 | 106 | Keep (demo: `src/demo/block5/tsql/00` to `03`). |
| 4.7 | new | **Test retrieval before you trust the answers.** See section 8. |
| 4.8 | new | Demo slide for `04_eval.sql`. See section 8. |
| 4.9 | new | **Where RAG goes wrong.** See section 8. |
| 4.10 | new | Ledger, section 4 rows. |

Slides 101 to 106 still carry "Jonathan-drafted ... KF to revise" notes; Kevin revises them
as part of this section.
Drop if long: 103.

Ledger rows:
- Worked: every one of 6 test questions found its runbook at rank 1. (Measured 2026-11-01 with
  the local Harrier model standing in for Foundry. **[fill]** with the Foundry run.)
- Worked: asked about something no runbook covers, the model said it didn't know instead of
  making something up. **[fill]** from the live run of the out-of-scope question in `03_rag.sql`.
- Broke: for a question no runbook covers, retrieval still handed the model four chunks
  (visible in the `retrieved_context` column of `03_rag.sql`). Retrieval always returns its
  top k, whether or not any of them answer the question. This row holds whatever model is used.
- Broke, if Foundry shows it too: the out-of-scope question's best match was nearly as close
  as a real answer's (Harrier: 0.595 vs 0.540), so distance alone can't tell "no answer" from
  "weak answer". **[fill]** with Foundry's numbers, or drop this row if Foundry separates them clearly.

### Section 5: Agents: the good and the bad (100 min, break in the middle)

Five steps, each giving the model more reach: before you hand it anything, briefing it,
pairing with it, letting it fetch context, letting it act. Then, how to guard it.

| New order | From | Action |
|---|---|---|
| 5.0 | 36 | Divider. Retitle "Agents: the good and the bad". |
| | | **Before you hand it anything** (Jonathan's Block 2 material) |
| 5.1 | 37 | Keep (who's pasted a production schema). |
| 5.2 | 38 | Keep (where your prompt goes). |
| 5.3 | 40 | Keep (what's at risk). |
| 5.4 | 41 | Keep (capability vs control tiers). |
| 5.5 | 42 + 43 | Merge into one slide, "Your AI use policy": approved tools and tiers, data classification decides the tier, and who signs off. |
| | | **Briefing it** (Kevin's Block 3 material) |
| 5.6 | 53 | Keep (R-C-T-C-O). |
| 5.7 | 56 | Keep (show it the relevant slice). |
| 5.8 | 55 | Keep (reason first, then iterate). |
| 5.9 | 60 | Keep (prompt makeover demo). |
| | | **Pairing with it** (Jonathan's 5.1 material) |
| 5.10 | 92 | Keep (the pair-programming loop). |
| 5.11 | 94 | Keep (five failure modes). |
| 5.12 | 95 | Keep (requirements to stored procedure demo). |
| | | **Letting it fetch context** (Jonathan's 5.2 material) |
| 5.13 | 96 | Keep. Change "Every good answer in the last section" to "Every good answer so far". |
| 5.14 | 98 | Keep (MCP video). Cut the static 97. |
| 5.15 | 99 | Keep (Learn MCP demo). Its text "The hallucination failure mode from 5.1" needs a new reference: "the failure modes from earlier in this section". |
| 5.16 | 100 | Keep (database MCP servers: power and risk). |
| | | **Letting it act** |
| 5.17 | 88 | Move from Block 4 (AI-assisted tuning and its guardrails). |
| 5.18 | 89 | Move from Block 4 (perf-triage demo, running as `sa`). See the note below. |
| 5.19 | new | **Agents in SSMS**, then the demo live or as screenshots (5.19a). The answer to 5.18's `sa` problem. See section 8 and `src/demo/block4/ssms-agent/`. |
| | | **Guarding it** (Jonathan's Block 6 material) |
| 5.20 | 112 | Keep (it's 50 lines). Change "In 5.2 you watched the AI fetch its own context" to "You just watched the AI fetch its own context". |
| 5.21 | 114 | Keep (the guardrail stack). |
| 5.22 | 115 | Keep (it works and it refuses demo). |
| 5.23 | 44 | Move here (the guardrail nobody tested). It shows that guardrails fail too. |
| 5.24 | 117 | Keep, but drop the "~90 hooks" sentence (slide 44 tells it). |
| 5.25 | new | Ledger, section 5 rows. |

Cut: 39, 45, 46, 47, 48, 49, 50, 51, 54, 57, 58, 59, 61, 91, 93, 97, 108, 109, 110, 111, 113, 116.

Slide 58 (troubleshooting with an LLM) is cut because 5.17 and 5.18 cover the same ground
with a live demo. Its one unique point ("hand over the plan, not just the SQL") goes into the
notes for 5.17.

Perf-triage note: the demo has Claude Code connect as `sa`. Say so on stage and put it on the
ledger. The agent did good work, but with the keys to everything. The SSMS demo right after it
(5.19) is the answer: the same kind of agent, with its own identity and rules.

Drop if long: 5.3, 5.8, 5.20.

Ledger rows:
- Broke: given the tables but not the real values, the model guessed `Severity = 'Critical'`, a value that doesn't exist; the query returned 0 rows (prompt makeover v2).
- Broke: a naive join turned 5 rows into 165 (prompt makeover v3).
- Worked: with the schema, real values, and constraints, the same model wrote a correct query (v4).
- Broke: **[fill]** the grain bug in the requirements-to-procedure demo.
- Worked: with the Learn MCP server, the model looked up and cited the real doc instead of guessing.
- Worked: the agent found the slow query's root cause and cut it from about 58,000 ms to about 290 ms of CPU with an identical result set. **[fill]** with the live numbers.
- Broke: it did that connected as `sa`.
- **[fill]** SSMS beat 1: whether Agent mode checked the real Severity values or guessed `'Critical'`.
- Worked: with the constitution in place, it used `Priority` and `Priority Foundation` with nobody typing them.
- Worked: asked for inspector names, it hit a permission error from SQL Server (Msg 230), not a polite refusal.
- Worked: the guarded MCP server refused the destructive request.

Slide 5.23 (the guardrail nobody tested) stays as a story, but it doesn't go on the ledger:
it happened before the talk, and its video (45) is cut.

### Section 6: Talking to leadership (35 min)

| New order | From | Action |
|---|---|---|
| 6.0 | 107 | Divider. Retitle "Talking to leadership". |
| 6.1 | new | **The ledger, in full.** All rows from the day on one slide (or two). |
| 6.2 | new | **Can agents replace the data team?** See section 8. |
| 6.3 | 32 | Move here (the four people you're selling to). |
| 6.4 | 33 | Move here (the two ways AI initiatives die). |
| 6.5 | 34 + 120 | Merge into **The pilot pitch**. See section 8. |
| 6.6 | 35 | Move here (bring the hard questions into the room early). |
| 6.7 | 118 | Keep (adoption roadmap). Cut the video version, 119. Phase II: change "Pilot one DIY tool on one team." to "Run one measured pilot: one table or one set of docs." (The DIY-tools slides are cut.) |
| 6.8 | 121 | Keep (do one thing Monday). |
| 6.9 | 122 | Keep (questions). |
| 6.10 | 123 | Keep (thank you). |

Drop if long: 6.6.

## 6. Cut list, all in one place

Cut (37): 5, 6, 7, 8, 11, 13, 14, 30, 39, 45, 46, 47, 48, 49, 50, 51, 54, 57, 58, 59, 61, 64,
69, 74, 75, 81, 87, 91, 93, 97, 108, 109, 110, 111, 113, 116, 119.

Merged into another slide (3): 43 into 42, 86 into 85, 120 into 34.

Old dividers 4, 36, 62, and 107 are reused with new titles; dividers 51 and 91 are cut.

New (16): 2 opening slides, 2 dividers (sections 2 and 4), 4 section ledgers, the full ledger
(6.1), and 7 content slides (3.12, 3.13, 4.7, 4.8, 4.9, 5.19, 6.2). Plus one screenshot slide
for the short version of the SSMS demo, which makes 100 if it's used.

123 - 37 - 3 + 16 = 99 slides. Every current slide is accounted for exactly once (checked by
script against the section tables).

**Demos cut:** the neural network demo (13, 14) and schema-blind vs context-aware (48). The prompt
makeover makes the same point as 48.

**Fixes carried over from the cut list** (still apply to slides that stay): remove the stage
directions printed on slides 95 ("lands 10x harder shown than told") and 115 ("that's the
credibility moment"), and move them to the notes if they're worth keeping. The ones on 48 and
100 go away with the cuts and rewrites.

## 7. Demo changes

| Demo | Status |
|---|---|
| `src/demo/block4/50_recall_check.sql` | **New.** Tested 2026-11-01 on the demo container (results above). Part A needs no embedding endpoint; part B needs Harrier running. Runs in about 5 seconds. |
| `src/demo/block5/tsql/04_eval.sql` | **New.** Tested 2026-11-01 against a scratch copy of the RAG database using Harrier in place of Foundry. **Kevin: run it once against Foundry before Friday.** |
| `src/demo/block4/perf-triage/` | Moves from Block 4 to section 5. No code change. |
| `src/demo/block4/ssms-agent/` | **New.** SSMS Agent mode before and after a `CONSTITUTION.md` with `agentExecuteAsUser`. SQL scripts tested 2026-11-01 in the container; Copilot itself needs a rehearsal on the Azure VM with a restored copy of WakeCountyFood. |
| Everything else | Unchanged. |

Container state to know before Friday: only 2,000 of about 311,000 violation comments are
embedded, and both vector indexes exist, so `FoodInspectionViolation` is read-only. The recall
numbers above are for that state.

## 8. New slide content

Drafts for Jonathan to lay out. Body text is the visible text; notes are the speaker notes.

### 0.4 What you'll leave with

Body (five lines):
- What vector data is, and why it isn't scary.
- How to store and search vectors in SQL Server, and a plan for a pilot in your own shop.
- How to work with AI agents, and where they go wrong.
- How to build a basic RAG system over your own documents.
- How to talk to leadership about all of it: what's possible and what isn't.

Notes: These are the five things the day is built around. If a slide doesn't serve one of
them, it isn't in the deck.

### 0.5 The ledger

Visual: an empty two-column table, "Worked" and "Broke".
Body: "Every demo today adds to this. At the end of the day, it's your evidence."
Notes: Explain that we'll fill this in as we go, and that the last section uses it to answer
the question every boss is asking: can we replace people with this?

### 3.12 Is the index giving the right answers?

Body:
- A vector index is approximate. It can return different rows than a full scan would.
- Measure it: run the same queries both ways and compare the top 10.
- Recall@10 = how many of the exact top 10 the index also found, divided by 10.
- Measure on your real data at your real size. Recall changes as the table grows.

Notes: This is the check you run before you tell anyone the pilot works. On SQL Server 2025,
VECTOR_DISTANCE is exact and VECTOR_SEARCH uses the index, so you can run both and compare.
Watch out for ties: violation comments repeat word for word, and when several identical
comments tie for 10th place, the two lists can pick different rows from the tie. The script
reports both a naive measure (INTERSECT of row IDs) and a tie-aware one.

### 3.13 Demo: measuring recall

Body: two columns. Left, "25 sample rows": recall@10 0.97, worst query 0.70. Right, "One
question": 8 of the top 10 in both lists.
Notes: `src/demo/block4/50_recall_check.sql`. Part A needs no endpoint. Part B embeds a typed
question. Numbers are from the 2,000-row demo set; rerun before the session and update.

### 3.21 Your pilot, step by step (replaces slide 90)

Body:
1. Pick one table with text people already search, and the questions they ask of it.
2. Pick an embedding model and an HTTPS endpoint.
3. Embed in batches. Skip blank text. Log what fails.
4. Search with exact kNN first. Under about 50,000 rows, you may never need an index.
5. If you index: build it last. On SQL Server 2025 the table goes read-only, and it needs an int clustered primary key.
6. Measure recall against exact search on a sample.
7. Time the embedding run, then do the math for the full table.

Notes: Each step points back to a slide or demo from this section. Step 7 is the capacity math
from 3.18. **[Kevin: if you have a measured embedding rate for Harrier on your laptop, rows per
minute, it makes step 7 concrete.]**

### 4.7 Test retrieval before you trust the answers

Body:
- An answer is only as good as the chunks retrieval found.
- Write down 10 to 20 real questions, and for each one, the document that should answer it.
- Run them after every change: chunk size, overlap, model, top-k, or the documents.
- Track two numbers: right document in the top k, and right document at rank 1.

Notes: This is the RAG version of the recall check from section 3. It never calls the chat
model, so it's cheap to run as often as you like. Include at least one question no document
answers.

### 4.8 Demo: testing retrieval

Body: a results table with columns question, expected document, rank, and in top 4 (from the
script's output).
Notes: `src/demo/block5/tsql/04_eval.sql`. The 2026-11-01 test run used local Harrier, not
Foundry: 6 of 6 at rank 1, and the out-of-scope question's best distance was 0.595 against
0.344 to 0.540 for real questions. **[fill]** with the Foundry run. If the Foundry run arrives
too late, show the table without numbers and run the script live.

### 4.9 Where RAG goes wrong

Body:
- It retrieves the wrong chunk, so the answer is confidently about something else.
- The document is out of date, so the answer is out of date.
- Nothing answers the question, but retrieval still returns its closest matches.
- A chunk splits a list of steps, so the answer gets half the procedure.
- Retrieval doesn't know who's asking. If a document is in the index, anyone can get it back.

Notes: The last one is the one DBAs should own. Row-level security or per-user filtering on
the chunk table is the fix; the model won't do it for you.

### 5.19 Agents in SSMS

Body:
- SSMS 22 has a Copilot Agent mode (GA in 22.10.2) that runs queries itself instead of only suggesting them.
- It's read-only by default.
- You can make it run as a lower-privilege user (EXECUTE AS; needs IMPERSONATE).
- You can give it rules per database: a CONSTITUTION.md or AGENTS.md stored as an extended property.
- Admins can turn Agent mode off by policy and limit which MCP servers it may use.

Notes: Facts checked on Microsoft Learn on 2026-11-01 (Agent mode preview in 22.7, GA in
22.10.2; the setting is `agentExecuteAsUser`; the approval prompt is explicitly not a security
boundary). It answers the `sa` problem: the agent's reach is something you configure.

Demo (Kevin): `src/demo/block4/ssms-agent/`, live (about 8 minutes) or as screenshots (about 2).
Jonathan needs one extra slide that can hold up to 8 screenshots for the short version
(file names are in the demo README; Kevin captures them in rehearsal). If it runs live, the
section needs the time from its drop-if-long list.

### 6.2 Can agents replace the data team?

Body: two columns, drawn from the ledger.
- Left, "What the agents did well today": drafting queries, finding similar text, looking up
  docs, a first diagnosis of a slow query.
- Right, "What needed a person": knowing `'Critical'` isn't a real value; spotting 5 rows
  becoming 165; deciding whether 0.97 recall is good enough; noticing the agent ran as `sa`;
  owning the result when it's wrong.

Notes: The answer comes from the ledger, not from us. The agents changed how fast the work
went. Every "Broke" row was caught by someone who knew the data. Ask the room which column
their job is in.

### 6.5 The pilot pitch (merges 34 and 120)

Body:
1. The painful problem, in their units: hours, tickets, risk.
2. A small pilot: one table or one set of documents, one set of test questions.
3. How you'll measure it: recall, retrieval hits, time saved. (You saw all three today.)
4. The risks and your guardrails, stated first.
5. The ask: time, budget, or access, and when you'll report back.

Notes: Point 3 is the difference from June. The section 3 and section 4 checks are the
measurement plan.

## 9. Writing rules for new and edited slides

These are the patterns that made the June deck read as machine-written. They apply to every
new or edited slide.

- No aphorism footers (one-line morals under the content). If the line matters, it goes in the body or the notes.
- No stage directions on the visible slide ("cliffhanger", "lands harder shown than told"). They go in the notes.
- Not every slide is a numbered list or a "vs." pair. Vary the layouts: a table, a single sentence, a screenshot.
- Specific beats general. "2 of 10 rows differed" beats "results may vary".
- Short words. No "leverage", "unlock", "landscape", "journey".
- Plain punctuation. The engine already removes em-dashes and ASCII arrows.

## 10. Left to the builder (Jonathan)

- Layout and visual style of the ledger slides, and how new rows are highlighted.
- Layout of every new slide. The section 8 text is content, not layout.
- Whether to show the ledger as one slide or two in 6.1.
- Footer numbering after the reorder.

## 11. Open items

- **[Kevin]** Real schedule for Friday (start, breaks, lunch), to replace the 360-minute assumption.
- **[Kevin + Jonathan]** Whether Kevin also presents 5.17 and 5.18 (see section 5).
- **[Kevin]** Run `04_eval.sql` and `03_rag.sql` against Foundry; fill the section 4 ledger rows.
- **[Kevin]** Rerun `50_recall_check.sql` if the embedded set changes; update 3.13.
- **[Kevin]** SSMS Agent mode: rehearse on the VM, capture the 8 screenshots, and check the three "verify in rehearsal" items in the demo README.
- **[Presenters]** Fill the **[fill]** ledger rows in rehearsal.
