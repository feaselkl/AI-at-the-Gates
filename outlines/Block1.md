# Block 1 — Foundations of Generative AI (1.1–1.5)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** Block 1 is 90 min (8:30 – 10:00). **1.1–1.4** (~65 min, concept
  foundations, Kevin) + **1.5 "Convincing the Boss"** (~15 min, the people problem,
  Jonathan — closes the block and sets up 6.4).
- **Audience:** Database professionals — DBAs, data engineers, database
  developers. Strong relational/T-SQL skills; **do not** assume linear algebra,
  trigonometry, or ML background. Build intuition from things they already know
  (rows, indexes, lookups, stored procedures).
- **Goal:** Build a mental model of how generative AI works, grounded in concepts
  data professionals already understand — so that the SQL Server 2025 vector work
  in Block 4 feels like an obvious next step.
- **Deliberate constraint:** **No SQL Server, no T-SQL in this block.** Block 1 is
  concept-and-intuition only, using free, browser-based or local tools. The
  database angle arrives in Block 4. (This replaces the earlier draft's two
  SQL-flavored demos.)

---

## How to read this outline

Per slide: **talking points**, an **image idea**, and **demo callouts** (`▶ DEMO`).

Unlike the Block 4 outline, Block 1 is concept-level, so it does **not** carry the
GA/Preview validation tags. The only tag used here is `[→ Block 4]`, marking a
deliberate forward-reference to where the SQL Server 2025 mechanics live. A short
**fact-check** list for the historical/technical claims is in the appendix.

**Running demo spine (all browser-based or local — no SQL Server):**
- **TensorFlow Playground** — what a neural network does.
- **A tokenizer web app** (e.g., tiktokenizer) — tokens & context windows.
- **A small local chat model via Ollama** — temperature/top-p, offline.
- **TensorFlow Embedding Projector** — embeddings, similarity, and (loaded with
  Wake County data) a preview of the Block 4 dataset. This tool is the visual
  thread tying 1.3 and 1.4 together.

---

## Section 0 — Block opener (2 slides, ~3 min)

### Slide 0.1 — "You already understand most of this"
- The promise: by the end of this block you'll understand embeddings and vectors
  well enough that Block 4's SQL Server vector features look obvious — with **no
  PhD math**.
- Reassurance for the room: we'll build every idea from things you already know.
- Honest framing: today is about *intuition first, mechanics later*.
- **Image idea:** The "castle gate" motif from the talk title, with a friendly
  on-ramp/road leading in. Warm, low-intimidation.

### Slide 0.2 — Block 1 roadmap (1.1–1.4)
- Four stops: (1.1) how we got here, (1.2) neural nets & LLMs, (1.3) embeddings,
  (1.4) vector storage — then 1.5, convincing the boss.
- The thread: text → numbers → meaning → similarity → storage.
- **Image idea:** A simple 4-stop progress map; reuse as a section divider so the
  gentle pace is visible.

---

## Section 1.1 — How We Got Here: The AI Timeline (5 slides, ~12 min)

### Slide 1.1.1 — Three eras, in terms you know
- **Rules-based systems:** humans hand-write the logic (think giant `CASE`
  expressions / stored procedures). Predictable, brittle, doesn't scale to
  fuzzy problems.
- **Machine learning:** instead of writing rules, you show examples and the system
  *learns* the pattern (like fitting a curve to data).
- **Deep learning → transformers/LLMs:** many-layered networks that learn rich
  patterns from massive text; the transformer (2017) made this scale.
- **Image idea:** A three-lane timeline ribbon, each lane with a familiar icon
  (rulebook → scatter-plot-with-fit-line → stack of layers).

### Slide 1.1.2 — Why generative AI is different from BI/analytics
- BI/analytics: **summarize known, structured data**; deterministic queries; same
  input → same answer.
- Generative AI: **produces new content** (text, code) from **unstructured** input;
  **probabilistic** — same prompt can give different answers.
- Neither replaces the other; genAI adds a new capability to your toolbox.
- **Image idea:** Side-by-side: a tidy pivot table/dashboard vs a free-text answer
  bubble. Label "deterministic" vs "probabilistic."

### Slide 1.1.3 — The next word is the whole trick
- LLMs fundamentally **predict the next token** given everything so far. Generation
  = doing that repeatedly.
- This one idea explains a lot of later behavior (creativity, hallucination).
- **▶ DEMO (no tech, 30 sec):** put a half-sentence on screen ("The health
  inspector walked into the kitchen and immediately noticed the…") and have the
  room call out the next word. That's what the model does — at scale.
- **Image idea:** A sentence with a blinking "next word?" slot and several candidate
  words with little probability bars.

### Slide 1.1.4 — Inflection points that matter for data work
- **2013 — word embeddings (word2vec):** words become vectors; "meaning as
  numbers" is born. *(This is the seed of 1.3.)*
- **2017 — the transformer ("Attention Is All You Need"):** the architecture behind
  modern LLMs.
- **2020–2022 — large models go mainstream** (GPT-3 → ChatGPT): scale + chat UX.
- **Now — vectors arrive in the database:** the convergence this whole course is
  about. `[→ Block 4]`
- **Image idea:** The timeline from 1.1.1, with these four pins highlighted and the
  last pin pointing at a database icon.

### Slide 1.1.5 — So what does this mean for you?
- You don't need to build models; you need to **store, secure, serve, and query**
  the data they produce and consume — squarely a data-platform job.
- That's why a DBA track on this is not optional anymore.
- **Image idea:** A DBA figure standing at the gate between "AI apps" and "the
  data," holding the keys.

---

## Section 1.2 — Neural Networks & LLMs Demystified (7 slides, 3 short demos, ~20 min)

### Slide 1.2.1 — What a neural network actually does (no math)
- It's a **function approximator**: given inputs, it learns to produce the right
  outputs by adjusting many small numbers ("weights") to fit examples.
- Analogy: a mixing board with thousands of dials; training nudges the dials until
  the examples come out right.
- "Deep" just means **many layers** of these adjustable units.
- **Image idea:** A mixing board / bank of dials morphing into a layered node
  diagram. No equations.

### Slide 1.2.2 — ▶ DEMO: watch a network learn (TensorFlow Playground)
- playground.tensorflow.org — pick the two-clusters dataset, hit run, watch the
  boundary form; add/remove neurons to show capacity.
- Takeaway: nobody wrote the rule for the boundary — it was *learned* from examples.
- **Image idea:** Screenshot of the Playground mid-train with the decision boundary
  forming. (Browser, no install.)

### Slide 1.2.3 — Text becomes tokens
- Models don't see characters or words exactly — they see **tokens** (subword
  chunks). Each token maps to a number.
- This is just another **encoding** step, like a lookup table.
- **▶ DEMO:** a tokenizer web app — paste a sentence, watch it split into tokens;
  paste an unusual word and see it fragment.
- **Image idea:** A sentence broken into colored token chips, each with an ID.

### Slide 1.2.4 — Context windows = working memory
- The **context window** is how many tokens the model can "hold in mind" at once.
- Too long → it gets truncated or forgets the start; bigger windows cost more.
- DBA analogy: the set of rows you can fit in one batch/buffer before spilling.
- **Image idea:** A sliding window over a long scroll of tokens; text outside the
  window grayed out.

### Slide 1.2.5 — Patterns vs facts (and why it hallucinates)
- LLMs learn **patterns of language**, not a database of verified facts.
- So they can produce fluent, confident, **wrong** answers — "hallucinations" — by
  predicting plausible next tokens.
- Operator takeaway: never trust output blindly; verify. (Foreshadows governance in
  Block 2.)
- **Image idea:** A confident-looking quote bubble with a small "citation needed"
  stamp.

### Slide 1.2.6 — The dials that shape output: temperature & top-p
- After the model ranks next-token options, **decoding parameters** decide how it
  picks: **temperature** = how random/creative; **top-p** = how wide a pool of
  candidates to sample from.
- Low temperature → focused, repeatable; high → varied, surprising.
- **Image idea:** A temperature dial from "boring/deterministic" to
  "wild/creative," with sample outputs at each end.

### Slide 1.2.7 — ▶ DEMO: temperature in action (local model)
- A small **local** chat model via Ollama (offline; reuses your Ollama setup).
  Same gentle, **non-SQL** prompt (e.g., "Suggest a name for a food truck")
  at temperature 0 vs ~1; run twice each.
- Takeaway: temp 0 ≈ same answer every time; high temp ≈ different each run.
- **Prep:** Harrier is embedding-only — pull a small *chat* model for this
  (e.g., `ollama pull llama3.2:1b`). See appendix.
- **Image idea:** Two columns of outputs (low vs high temp) for the same prompt.

---

## Section 1.3 — Embeddings: Turning Data into Vectors (6 slides + demo, ~18 min)

### Slide 1.3.1 — The big idea: meaning as a list of numbers
- An **embedding** turns a piece of data (a word, sentence, code snippet, row) into
  a fixed-length **vector** — a list of numbers — that captures its meaning.
- The magic property: **similar things land near each other** in that number space.
- This single idea powers semantic search, RAG, recommendations — and Block 4.
- **Image idea:** A word ("kitchen") flowing into a bracketed list of numbers, then
  a dot placed on a 2D map near related words.

### Slide 1.3.2 — Where the numbers come from
- An **embedding model** (itself a neural network) produces the vector. You feed in
  text; you get back, say, a 1024-number vector.
- It was trained so that things meaning the same end up close — you don't set the
  numbers by hand.
- You can embed text, **code**, and even database rows/objects the same way.
- **Image idea:** A black-box "embedding model" with text in and a vector out;
  several different inputs → dots clustering by topic.

### Slide 1.3.3 — Similarity = distance (cosine, without trig)
- "How similar are two things?" becomes "how close are their vectors?"
- **Cosine similarity** intuition: do the two arrows **point the same direction**?
  Same direction = similar; perpendicular = unrelated. (No trig required.)
- **Image idea:** Two arrows from an origin — a tight angle ("similar") vs a wide
  angle ("different"). Keep it to two arrows, not a math lesson.

### Slide 1.3.4 — ▶ DEMO part A: the classic intuition (Embedding Projector)
- projector.tensorflow.org with built-in word vectors: search "king," show nearest
  neighbors; demonstrate the famous **king − man + woman ≈ queen** analogy.
- Takeaway: directions in the space actually mean something.
- **Image idea:** Projector screenshot with "king/queen/man/woman" highlighted in
  the 3D cloud.

### Slide 1.3.5 — ▶ DEMO part B: our real data (Wake County)
- Load **precomputed embeddings of Wake County food-inspection violation comments**
  into the Projector. Show that comments about temperature cluster together, pest
  issues elsewhere, cleanliness elsewhere.
- Click one comment → its **nearest neighbors** are semantically similar comments,
  even with different wording. **That is semantic search**, seen with your eyes.
- This is the *same dataset* you'll query in SQL Server in Block 4 — planted now.
  `[→ Block 4]`
- **Prep:** generate `vectors.tsv` + `metadata.tsv` offline with the Harrier model
  (via Ollama) — see appendix. All client-side; nothing to install for attendees.
- **Image idea:** Projector 3D cloud of violation comments with two or three labeled
  clusters circled.

### Slide 1.3.6 — Why a data pro should care
- Keyword search finds the **words you typed**; semantic search finds the **meaning**
  — "fridge too warm" matches "improper cold holding" with no shared keywords.
- This unlocks search, dedup, clustering, and RAG over your own data.
- **Image idea:** Two search bars — keyword (misses the synonym) vs semantic (finds
  it) — over the same data.

---

## Section 1.4 — Vector Storage: The Data Platform Angle (5 slides, ~12 min)

### Slide 1.4.1 — Vectors aren't like the data you usually store
- Relational storage is built for **exact** answers: equality, ranges, B-tree
  seeks, `JOIN`s on keys.
- Vectors are about **similarity**, are **high-dimensional**, and have **no exact
  match** — "find the closest" replaces "find equal."
- **Image idea:** A neat keyed table (exact rows) beside a fuzzy cloud of points
  (nearest neighbors). Contrast the two questions they answer.

### Slide 1.4.2 — "Close enough": approximate nearest neighbor (ANN)
- **Exact** nearest-neighbor compares your query to **every** vector — accurate but
  slow at scale.
- **Approximate (ANN)** trades a tiny bit of accuracy for a huge speed-up by being
  clever about what to compare.
- **Recall** (gentle): the fraction of the true closest items ANN actually finds —
  usually near-perfect, and that's fine.
- Why it's OK: embeddings are *already* an approximation of meaning, so "close
  enough" really is close enough.
- **Image idea:** Left: a query point with lines to every dot ("exact, slow").
  Right: lines to just a nearby neighborhood ("approximate, fast").

### Slide 1.4.3 — Three knobs, conceptually
- **Dimensions:** how long the vector is (e.g., 1024 numbers for the Harrier model
  we used). More dimensions = more nuance, more storage.
- **Distance metric:** how you measure "closeness" — cosine, Euclidean, dot
  product. Pick one and stick with it.
- **Index type:** how vectors are organized for fast ANN (graph-based,
  cluster-based). Names only here — mechanics in Block 4. `[→ Block 4]`
- **Image idea:** Three small cards — a ruler (dimensions), an angle/measure
  (metric), a little graph/cluster sketch (index).

### Slide 1.4.4 — ▶ DEMO (light): ANN is what you just saw
- Back in the Embedding Projector: the "nearest neighbors" you clicked **is** ANN at
  work, and the 3D view itself is an approximation of a 1024-dim space.
- Takeaway: you've already used approximate similarity search — without a database.
- **Image idea:** Callout over the earlier Projector neighbors view: "this is ANN."

### Slide 1.4.5 — Setting the stage for Block 4
- You now understand vectors, similarity, ANN, and the knobs. Block 4 shows how
  **SQL Server 2025** stores them (the `VECTOR` type), indexes them (DiskANN), and
  searches them — in T-SQL, on the very data you just visualized. `[→ Block 4]`
- The leap from "dots in a browser" to "rows in your database" is smaller than it
  looked at 8:30.
- **Image idea:** The browser dot-cloud morphing into a database table with a vector
  column; a bridge labeled "Block 4."

---

## Section 1.4 wrap-in (1 slide, ~1 min)

### Slide 1.W — Mental model recap
- One line to remember: **text → tokens → embeddings (vectors) → similarity →
  storage/search.**
- You can reason about every AI-data feature for the rest of the day from this
  chain.
- Next (1.5): the people problem — hype, fear, and convincing skeptical seniors.
- **Image idea:** The five-link chain assembled, each link an icon from this block.

---

## Section 1.5 — Convincing the Boss `[JS]` (5 slides, ~15 min, closes the block)

> The bridge from "how it works" to "why your org should care." Hand attendees the
> language to win over skeptical leadership — and to spot when the skepticism is
> *correct*. Plants the seed that 6.4 (Adoption Roadmap) pays off at 5:00 PM.
> Discussion/framing — **no demo** (optional: one real, sanitized before/after
> time-savings number as a credibility anchor). `[→ 6.4]`

### Slide 1.5.1 — The gap, and the honest pitch (hook)
- "You understand how this works now. Your boss doesn't — and the person signing the
  PO trusts a vendor demo and a LinkedIn post more than they trust you. This section
  closes that gap without making you the hype person."
- Posture: we're not selling AI; we're making a *defensible* case — being the person
  who can name the risks out loud. That credibility is the whole game.
- **Image idea:** A presenter between an excited "believer" and a skeptical "boss,"
  holding a one-page plan.

### Slide 1.5.2 — The four people you're selling to
- **The True Believer** (often CEO/VP) — saw a demo, wants "AI" on the roadmap, no
  specifics. Danger: budget without direction.
- **The Terrified** — fears a hallucinated `DROP TABLE` in prod or PII leaking to a
  vendor; often security/compliance. *Frequently your best ally* — their questions are
  the ones you want answered.
- **The Burned** — lived through "big data," "blockchain," "low-code replaces devs."
  Skepticism earned, not irrational.
- **The Quietly Already-Using-It** — pasting prod schemas into ChatGPT right now. Say
  "no" and you don't stop it — you just stop *knowing about it*.
- > Key line: "Every one is partly right. Your job isn't to defeat them — it's to give
  each the specific thing they need to say yes."
- **Image idea:** Four labeled archetype cards around a boardroom table.

### Slide 1.5.3 — The two ways AI initiatives die (pick the middle)
- **Over-promise** → "It'll write all our T-SQL." First wrong answer in prod, project
  dead, you own the blame. `[→ 5.1]`
- **Over-fear** → "We can't use it, it's a data-leak risk." Competitors ship faster;
  your team uses it in the shadows anyway.
- The honest pitch sits in the middle: **AI is a force multiplier for people who
  already know what good looks like, and a liability amplifier for people who don't.**
- > Key line: "Don't sell magic. Sell leverage. Magic gets you one budget cycle.
  Leverage gets you a program."
- **Image idea:** A dial between "over-promise" and "over-fear," needle in the middle.

### Slide 1.5.4 — The convince-the-boss playbook (the write-it-down slide)
- Five moves, in order:
  1. **Lead with the risk slide, not the demo** — name the data/compliance/accuracy
     risks *and* your mitigations first; you disarm the Terrified and out-credential
     the vendor who skipped it. (This is literally why 2.1 Security is next.) `[→ 2.1]`
  2. **Pick a boring, bounded first win** — one painful, low-stakes, high-frequency
     task (documenting legacy procs, `sp_` boilerplate). Boring = low blast radius = easy yes.
  3. **Quantify in their units** — "this class of ticket is ~3 hrs; with AI-assisted
     drafting + review it's ~45 min." Hours and tickets, not vibes.
  4. **Show the guardrails before they ask** — human-in-the-loop, no prod write access,
     enterprise tier with training opt-out, an AUP. The sentence that unlocks budget. `[→ 2.1]`
  5. **Ask for a pilot, not a platform** — a 30-day, one-team, one-task pilot with a
     success metric. Reversible, cheap; converts the Burned with evidence. `[→ 6.4]`
- **Image idea:** A numbered 5-move card (the photograph slide).

### Slide 1.5.5 — The skeptic is your free risk assessment (+ transition)
- Reframe: you *want* the hard questions early. The DBA who asks "what happens when it
  hallucinates an index hint?" is doing your risk assessment for free — bring them in
  as a reviewer, not a roadblock.
- > Closing line: "You don't convince the boss by being the most excited person in the
  room — by being the most *credible* one, who already thought about what could go
  wrong. Which is exactly what we do next: we talk security."
- Transition into Block 2 / 2.1: "The fastest way to lose this argument is to fumble
  'is it safe?' — so let's make sure you never do." `[→ 2.1]`
- **Image idea:** A skeptic's question turning into a checklist item labeled "free QA."

---

## Appendix — Presenter prep & fact-check (not slides)

### Demo prep (do once, before the talk)
- **TensorFlow Playground / tokenizer / Embedding Projector:** browser tools, no
  install. Pre-open tabs; pre-load the Projector state if possible.
- **1.2 temperature demo (local chat model):** Ollama is already set up for Block 4
  (see `src/infra/ollama/`). Harrier is **embedding-only**, so pull a small **chat**
  model for this demo, e.g. `ollama pull llama3.2:1b` (or `qwen2.5:0.5b`,
  `gemma2:2b`). Run the same prompt at `temperature` 0 and ~1 (LM Studio works too).
- **1.3 Wake County Projector files:** generate two TSVs offline from the violation
  comments using the Harrier model (via Ollama), then load them in the Projector
  (the "Load" button — all client-side):
  - `vectors.tsv` — one embedding per line, tab-separated numbers.
  - `metadata.tsv` — the matching comment text (and maybe severity) per line, for
    labels/coloring.
  - Sample a few thousand comments so the cloud is readable and load is fast.

### Fact-check (verify before delivery)
- word2vec — Mikolov et al., **2013** (Google).
- "Attention Is All You Need" (the transformer) — Vaswani et al., **2017**.
- GPT-3 — **2020**; ChatGPT public release — **November 2022**.
- Harrier (`microsoft/harrier-oss-v1-0.6b`) embedding dimension — **1024**.
- Cosine / Euclidean / dot product are the common distance metrics (consistent with
  what Block 4 uses in SQL Server 2025).
