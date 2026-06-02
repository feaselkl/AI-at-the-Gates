# Block 6 — Building Your Own AI-Powered Tools (6.1–6.4)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** Block 6 is 75 min (3:45 – 5:00) — the closing block. 6.1 vibe
  coding (~20 min), 6.2 build an MCP server (~25 min, the day's payoff), 6.3 other
  DIY ideas (~15 min), 6.4 adoption roadmap (~15 min, the close). Tight window with
  no slack — protect 6.4.
- **Audience:** DBAs, data engineers, database developers. Many do **not** call
  themselves "developers" — 6.1 must convince them they can still build. By now
  they've used MCP (5.2) and seen every component of the day.
- **Goal:** Empower attendees to build their own AI-enhanced tools — vibe-coded
  utilities, a real SQL Server MCP server with guardrails, and a menu of DIY ideas —
  then convert the whole day into a Monday-morning plan.
- **Throughline:** every build is the same recipe — **a model + your context
  (MCP/RAG/metadata) + a guardrail + a place users already are.** Security is not a
  bolt-on; it's why the talk is credible to a risk-aware room.

---

## How to read this outline

Per slide: **talking points**, an **image idea**, and demo callouts (`▶ DEMO`).
Tags: `[Concept]` for platform-neutral ideas, `[Non-MS]` for third-party tools,
`[→ Block N]` / `[→ X.Y]` for callbacks. A presenter **prep & fact-check** list is
in the appendix. **Two live demos** (6.1 vibe-code a utility, 6.2 build an MCP
server); 6.3 is idea-survey (no demo by default); 6.4 is synthesis.

---

## Section 6.0 — Block opener (1 slide, ~1 min)

### Slide 6.0 — From "use it" to "build it"
- All day you've *used* AI tools others built. The last 75 minutes flips it: you
  leave as someone who can *build* — a utility, an MCP server, a backlog of ideas.
- Roadmap: vibe coding (6.1) → your own MCP server (6.2) → other DIY builds (6.3) →
  your Monday plan (6.4).
- **Image idea:** The "castle gate" motif, now with the attendee standing *inside*
  holding the keys — flipped from the 8:30 opener.

---

## Section 6.1 — Vibe Coding: A Primer for Data Professionals (6 slides + demo, ~20 min)

### Slide 6.1.1 — The utility you never built
- Hook: "Who's needed a little tool — rename 400 columns, parse a gnarly log,
  reformat an export — and skipped it because it wasn't worth a day of coding?"
- Vibe coding makes that a 20-minute job: describe in plain English → AI writes →
  you test → you ship. You don't have to *be* a developer to *direct* one.
- Honest caveat up front (separates you from the hype): "It's real and powerful.
  It's also where people build confident garbage and ship it. I'll show you both."
- **Image idea:** A sticky note "tool I never built" turning into a running script.

### Slide 6.1.2 — What vibe coding is — the non-developer's unlock
- Term coined ~2025: build software by describing intent and iterating on what the
  AI produces, instead of writing every line. `[Concept]`
- Why it matters for *data* people specifically: you have the domain knowledge and
  you know what "correct" looks like — you were only missing typing speed and syntax.
- Reframe of 5.1: pair programming improves how *developers* work; vibe coding lets
  *non-developers build at all.* Same engine, different unlock. `[→ 5.1]`
- **Image idea:** A DBA at a keyboard with the AI as a second pair of hands.

### Slide 6.1.3 — Choosing your tool (match to the job)
- **Conversational/agentic builders** — Claude / Claude Code `[Non-MS]` (home
  turf): "build me this script" end-to-end.
- **AI-native editors** — Cursor, Windsurf `[Non-MS]` (callback to 2.3) for
  project-scale work you'll maintain. `[→ 2.3]`
- **Browser app-builders** — Bolt, Replit, v0 `[Non-MS]`: "describe an app, get a
  running app" — lowest barrier, best for non-technical users and UI prototypes.
- Match: throwaway script → conversational; tool you'll maintain → editor + git;
  quick app for a business user → browser builder. (Echoes the 2.3 framework.)
- **Image idea:** Three lanes (chat / editor / browser-builder) with a job tag on each.

### Slide 6.1.4 — Best practices: how to not get burned (the write-it-down slide)
- **Describe outcomes, not implementation.** "Find duplicate customers by email,
  output a CSV" beats "write a Python loop that…". You own the *what*; it picks the *how*.
- **Work in small steps.** One capability at a time; test each before the next.
- **Test rigorously — non-negotiable.** Run on real(istic) input; check edge cases.
  *You* are the QA; the AI won't tell you it's wrong. `[→ 2.1]` `[→ 5.1]`
- **Course-correct early.** Drift at step 2 is cheap to fix; at step 8 it's a tangle.
- **Stay the architect.** You decide what gets built and whether it's right. The AI
  is the hands, not the brain.
- **Image idea:** A 5-rung checklist card (the photograph slide).

### Slide 6.1.5 — When vibe coding ISN'T enough (the "don't get burned" slide)
- **Complex business logic** — more domain nuance = more wrong guesses.
- **Performance-critical / production-scale paths** — fine for a one-off, risky for
  anything hammering prod (review it like any code — `[→ 5.1]`).
- **Unfamiliar domains** — if *you* can't tell whether the output is correct, vibe
  coding is dangerous, not magic. You can only QA what you understand.
- **Security-sensitive code** — auth, secrets, prod writes: vibe-code the draft,
  review like your job depends on it.
- **The maintenance trap** — code you didn't write and don't understand is code you
  can't maintain. Fine for throwaway; think twice for load-bearing.
- **Image idea:** Five caution signs, one per pitfall.

### Slide 6.1.6 — ▶ DEMO: vibe-code a database utility from scratch
- Pick a small, useful, *finishable* utility: read a table → generate a draft data
  dictionary; or a CSV-diff tool; or a bulk column-renamer from a mapping file.
- Show the loop honestly: describe → run → slightly wrong → correct in plain English
  → run → working. Include **one real course-correction** (proves the method).
- **Backup:** pre-recorded capture + finished script saved. Pick a tool that demos
  fast and visibly (home-turf Claude Code, or a browser builder for relatability).
- **Image idea:** Split: plain-English request on the left, working tool on the right.

---

## Section 6.2 — Standing Up Your Own MCP Server (6 slides + demo, ~25 min — the day's payoff)

### Slide 6.2.1 — It's 50 lines, not magic
- Hook: "In 5.2 the AI fetched its own context and it felt like magic. It's about
  50 lines of code and a config entry — and you're about to watch me write it." `[→ 5.2]`
- The honest bar (your Live!360 thesis): "The tutorial teaches you to *register* a
  tool. Production teaches you to *ship* one safely. An AI-called tool has a
  different threat model than an API a human calls."
- **Image idea:** A small code file labeled "MCP server (~50 lines)" next to a big
  "product" box, equals sign between them.

### Slide 6.2.2 — Architecture, made concrete (deeper than 5.2)
- **Tools** — functions the AI can *invoke* (`describe_table`, `run_select`): name +
  a description the model reads to decide when to call + an input schema.
- **Resources** — readable context the AI can *pull* (schema dump, runbook, docs).
- **Prompts** — server-provided prompt templates.
- The loop: client launches the server (stdio/local or HTTP) → handshake
  capabilities → model picks tools → server executes → returns results.
- Key mental model: **the tool's *description* is part of the prompt** — you're
  prompt-engineering the tool surface. `[→ 3.1]`
- **Image idea:** Client ↔ server ↔ DB, with Tools/Resources/Prompts labeled on the server.

### Slide 6.2.3 — The build, in 5 steps (the roadmap you build against)
1. Instantiate the server, declare capabilities.
2. Register one **resource**: the database schema (tables/columns) as readable context.
3. Register one **tool**: `run_select` — execute a read-only query, return rows.
4. Wire the DB connection — parameterized, **least-privilege login**.
5. Add the server to the client config (`.mcp.json`) and connect.
- Philosophy: genuinely from-ish scratch but **de-risked** — a tested scaffold you
  fill in live beats typing 200 lines and praying.
- **Image idea:** A numbered 5-step ladder.

### Slide 6.2.4 — What you expose: metadata · query execution · docs
- **Metadata** → `INFORMATION_SCHEMA` / `sys.*` as a resource: the AI now knows the
  real schema — the thing that killed the 5.1 hallucination. `[→ 5.1]`
- **Query execution** → the `run_select` tool: the AI asks the *data* questions, not
  just reads structure.
- **Docs/runbooks** → resources: tribal knowledge becomes AI-accessible context —
  the bridge to Kevin's 5.3 RAG. `[→ 5.3]`
- **Image idea:** Three feeds (metadata / query / docs) flowing into the AI client.

### Slide 6.2.5 — Security guardrail stack (DO NOT SKIP — the differentiator)
- **Read-only by default.** Least-privilege login (`db_datareader`). The model can't
  `DROP` what its credential can't `DROP` — defense in depth, not just a code check.
- **Parameterize / validate at the boundary.** The AI writes the params — treat them
  as user input. Allowlist identifiers; reject anything that isn't a `SELECT` (parse,
  don't regex-and-pray). `[→ 2.1]`
- **Statement guards.** Block multi-statement batches, `;`-stacking, `xp_cmdshell`,
  DDL. Enforce a row cap + query timeout so the AI can't melt the box.
- **Credential hygiene.** Secrets out of code *and* out of the prompt; errors never
  leak connection strings back to the model.
- **Prompt injection via results.** Returned data can carry instructions ("ignore
  previous instructions and…"). Name the class; point at the production answer (Live!360).
- **The external hooks layer.** Above the server's own SELECT-only check, a Claude
  Code **hook** fires on every tool call — a second gate that doesn't trust the
  server got it right. Caution (the dead-guardrail war story from 2.1): a hook only
  protects you if it actually *fires and blocks* (`exit 2` / JSON `{"decision":"block"}`,
  not a warning that prints and lets it through). `[→ 2.1]`
- > Key line: "The guardrail isn't one check — it's a stack. Any one can fail; the
  stack still holds. That's the difference between a demo and production."
- **Image idea:** Stacked gates (least-priv → SELECT-only parse → caps/timeouts →
  cred hygiene → external hook), each labeled "any one can fail."

### Slide 6.2.6 — ▶ DEMO: build & connect a SQL Server MCP server (the day's payoff)
- From a minimal tested scaffold, **live-add** the schema resource + `run_select`
  tool; add to `.mcp.json`; connect; ask a natural-language question → the AI calls
  the tool against the real demo DB → **real rows**.
- **Show one guardrail working:** ask for something destructive → the read-only
  login / SELECT-only guard **refuses** (show the refusal — that's the credibility moment).
- **Fold in the hooks beat (30–60 sec, the day's only live hooks moment):** before
  the request reaches the server, a Claude Code hook fires on the tool call and
  blocks it; then note the server-side SELECT-only guard would *also* have caught it.
  Two independent gates. Say the line: "a hook only protects you if it actually fires —
  mine once didn't." Do **not** expand into a hooks tutorial.
- **Backups (highest-risk demo of the day — over-prepare):** pre-built server to
  `git checkout`; full screen recording of build → connect → query → refusal → hook
  block; static terminal output as last resort.
- **Image idea:** Client window showing a NL question → tool call → rows, with a red
  "BLOCKED" overlay on the destructive attempt.

---

## Section 6.3 — Other DIY AI Solutions (6 slides, idea-survey, ~15 min)

### Slide 6.3.1 — Starter kit, not the whole kit
- "You've vibe-coded a utility and built an MCP server. Those are the *starter kit* —
  here are four more a data team can actually ship, so you leave with a backlog."
- Throughline: every one is the same pattern — **AI + your context + a guardrail** —
  pointed at a different surface.
- **Image idea:** Four tool cards fanned out from a "starter kit" box.

### Slide 6.3.2 — Slack / Teams support bot
- A channel bot that answers "what's the schema for X," "is job Y running," "explain
  this error" — LLM + your context (often the very MCP server from 6.2). `[→ 6.2]`
- Why it lands: meets people where they are; deflects the repetitive questions that
  interrupt the DBA all day — "first-line support that never sleeps."
- Guardrail note: read-only, scoped, **logged** — a bot anyone can DM is a bigger
  attack surface than your laptop.
- **Image idea:** A Teams channel with the bot answering a schema question.

### Slide 6.3.3 — Automated runbook assistant
- Turn static runbooks/incident docs into a thing you can *ask*: "how do we fail over
  the reporting replica?" → grounded answer from your actual runbook.
- RAG-shaped — mechanics belong to Kevin's 5.3; here it's framed as *a tool you
  build*, not the technique. `[→ 5.3]`
- Killer value (say the line): tribal knowledge survives the person who leaves.
- **Image idea:** A runbook PDF with a chat bubble asking it a question.

### Slide 6.3.4 — AI in CI/CD for database deployments
- Drop AI review into the deploy path: auto-review migration scripts for
  anti-patterns, flag risky changes (a `DROP`, a non-online index build, a missing
  `WHERE`), draft rollback scripts, summarize what a PR actually changes.
- Why DBAs care: a second reviewer on every migration, at PR time — catches the 3 AM
  mistake before prod.
- Guardrail note: AI **advises**, a human still approves. Never the sole approver.
- **Image idea:** A PR diff with an AI review comment flagging a risky migration.

### Slide 6.3.5 — Text-to-SQL for business users (high value, highest care)
- Let non-technical users ask in English over a *curated, governed* view of the data.
- Honest caveat (the one most likely to embarrass you): text-to-SQL on a messy schema
  produces confidently wrong numbers. It works when scoped to clean, well-named,
  documented models with guardrails — **not** pointed at raw prod.
- The schema/metadata (and your 6.2 MCP server) are what make it viable. `[→ 6.2]`
- **Image idea:** A business user typing a question over a small "governed model" box.

### Slide 6.3.6 — The recipe behind all four (the takeaway)
- Same every time: **a model + your context (MCP/RAG/metadata) + a guardrail + a
  place users already are.** See the recipe and you can invent the fifth yourself.
- Proof point (spoken aside, no live build): this recipe is how ~90 "hooks" run
  across your own AI setup. Two hard-won cautions: (1) **test that the guardrail
  actually fires** — one shipped with a dead check; (2) **watch the blast radius** —
  one badly-written guardrail ran on every action and hung the whole assistant. A
  guardrail is code: it earns the same testing and performance care as what it guards.
- **Image idea:** The recipe as one equation, four example surfaces beneath it.

---

## Section 6.4 — Your AI Adoption Roadmap (6 slides, ~15 min — closes the day)

### Slide 6.4.1 — What do you do Monday?
- Bookend the day: "We opened by talking about convincing your boss — we close by
  making sure you have something worth convincing them *of*." `[→ 1.5]`
- Everything collapses to one question: what do you do Monday morning? Here's the roadmap.
- **Image idea:** A calendar with "Monday" circled, a single arrow out of the whole day.

### Slide 6.4.2 — The phased roadmap (the single takeaway slide)
- **This week** · **This quarter** · **The horizon** — one slide, three columns.
- Built so each of the 1.5 archetypes gets a yes: the quick win for the skeptic, the
  vision for the believer, the guardrails for the terrified. `[→ 1.5]`
- **Image idea:** A three-band timeline; reuse as the printable handout.

### Slide 6.4.3 — Quick wins: this week (zero budget, zero approval)
- Use an assistant for the boring, bounded task (docs, boilerplate, explaining legacy
  procs) — the 1.5 "boring first win." `[→ 1.5]`
- Stand up the Microsoft Learn MCP server (5.2) — free, no data leaves, immediate. `[→ 5.2]`
- Run AI code review on your next migration by hand before it ships (6.3). `[→ 6.3]`
- The point: build **evidence** this week. A skeptic converts on a before/after time
  number, not a TED talk. `[→ 1.5]`
- **Image idea:** Three "do it now" cards with a stopwatch.

### Slide 6.4.4 — Medium-term: this quarter (with a paper trail)
- Draft and propose the AI acceptable-use policy (2.1) — be the person who brings the
  *governed* path. `[→ 2.1]`
- Build your first real MCP server for your own database (6.2), with guardrails. `[→ 6.2]`
- Pilot one DIY tool (6.3) on one team with a defined success metric — "pilot, not
  platform" from 1.5. `[→ 1.5]`
- Theme: personal productivity → *team* leverage, documented.
- **Image idea:** A quarter calendar with three milestones pinned.

### Slide 6.4.5 — The business case (the 1.5 payoff)
- You now have quick-win evidence, a governance story, and a phased plan. That *is*
  the business case.
- The one-page pitch: **painful problem → bounded pilot → guardrails → measured
  result → the ask.** (Pairs with a downloadable roadmap template — lead-magnet.)
- Long-term, honest: vectors/semantic search become normal DB features (Block 4);
  AI-assisted tuning/ops become routine; the DBA's role shifts toward *governing*
  AI-augmented systems, not competing with them. "It changes what you spend your day
  on — less typing, more judgment. The judgment was always the job." `[→ Block 4]`
- **Image idea:** A one-page pitch template with the five blanks filled.

### Slide 6.4.6 — Pick your one thing (send-off → Q&A)
- "You don't have to do all of this. You have to do *one* thing Monday — the smallest
  useful thing from today — and then have a result to show. Pick it before you leave."
- Hand to the joint Wrap-Up / Q&A with Kevin (5:00–5:30) + the resource list.
- **Image idea:** A single checkbox captioned "my one thing," then a "Q&A" bumper.

---

## Section 6 wrap-in (handled by 6.4.6 → joint Wrap-Up)

> Block 6 ends straight into the joint Wrap-Up / Q&A (5:00–5:30). No separate wrap
> slide — 6.4.6 *is* the close. Kevin runs Q&A logistics; confirm the handoff line.

---

## Appendix — Presenter prep & fact-check (not slides)

### Demo prep (do before the talk)
- **6.1 vibe-code demo:** lock the utility — small, DB-adjacent, *finishes live with
  buffer* (data-dictionary generator / CSV-diff / column-renamer). Stage a full
  fallback recording + finished script. Decide tool: home-turf Claude Code vs. a
  browser builder for non-dev relatability.
- **6.2 MCP build demo (highest-risk of the day — over-prepare):**
  - **Verify the current MCP SDK API via context7 before writing demo code — the SDK
    is pre-1.0 and moves every release.** Stack default: TypeScript +
    `@modelcontextprotocol/sdk` (Python equally valid for the audience).
  - Minimal tested scaffold staged; live-add only the schema resource + `run_select`.
  - **Least-privilege login** (`db_datareader`) created on the demo DB; connection
    parameterized; secrets in env/secret store, not in code or prompt.
  - Client `.mcp.json` tested end-to-end on the **actual demo machine**.
  - **Pre-install and verify the blocking hook actually fires** (`exit 2` / JSON
    `decision:block`, not a non-blocking warning) — do not demo a dead guardrail
    while telling the dead-guardrail story.
  - Backups: pre-built server to `git checkout`; full recording of build → connect →
    query → guardrail-refusal → hook block; static output as last resort.
- **Demo DB continuity:** reuse one schema across 5.1 / 6.1 / 6.2 (decide which).
- **6.3:** default **no demo** (protect 6.4). The ~90-hooks aside is spoken, no
  slide. Only if 6.2 finishes early: one 60–90 sec recording (Teams bot or CI review
  comment), hard cap, then move on.

### Fact-check (verify before delivery — these move fast)
- **MCP** = Model Context Protocol, open standard; SDKs are pre-1.0 — re-verify the
  API used in the live build via context7 close to the event.
- **Claude / Claude Code / Cursor / Windsurf / Bolt / Replit / v0** — third-party
  `[Non-MS]`; confirm the lineup and naming near the event (the builder space churns).
- **Hooks** behavior (Claude Code): a blocking hook uses `exit 2` or JSON
  `{"decision":"block"}`; a plain non-zero exit + stderr is a *non-blocking* warning.
  Re-confirm against current Claude Code docs before the live beat.

### Coordination with Kevin
- 6.3 runbook-assistant **points to** 5.3 RAG — don't re-teach the mechanics.
- 6.2 metadata/docs-as-resources is the build-side bridge to 5.3's retrieval side.
- Confirm the 6.4 → Wrap-Up handoff choreography (Kevin runs Q&A logistics).
