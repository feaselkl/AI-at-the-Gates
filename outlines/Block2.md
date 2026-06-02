# Block 2 — The AI Tooling Landscape + Security & Governance (2.1–2.4)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** Block 2 is 75 min (10:15 – 11:30). 2.1 Security/Governance (~30 min,
  opens — the largest morning slot), 2.2 Built-In AI Features (~15–18 min), 2.3
  Standalone AI Tools (~15 min), 2.4 Evaluating New Tools (~10 min).
- **Audience:** DBAs, data engineers, database developers — a **risk-aware** room.
  Security leads, deliberately, so they spend the rest of the day listening instead
  of silently objecting.
- **Goal:** Answer "is this safe to use?" *before* "here's how to use it"; survey
  what's already in their toolkit and what they go get; and hand them a durable
  method for judging tools that don't exist yet.
- **Owners:** 2.1, 2.3, 2.4 — Jonathan; 2.2 — Kevin. Security framing (2.1) is the
  spine the rest of the day hangs on; the "tier decides the tool" idea recurs in 2.3.

---

## How to read this outline

Per slide: **talking points**, an **image idea**, and demo callouts (`▶ DEMO`).
2.2 is a tooling survey, so its claims carry a light status tag — `[GA]`,
`[Preview]`, `[Non-MS]` (third party), `[Concept]` — verified against Microsoft
Learn (June 2026). A presenter **fact-check** is in the appendix.

---

## Section 2.0 — Block opener (1 slide, ~1 min)

### Slide 2.0 — Safe first, then which tool
- The block's order is the point: **security → what's built in → what you go get →
  how to evaluate the next thing.** A risk-aware DBA audience earns honest framing.
- "By the end you'll have a security stance, a decision framework, and a checklist —
  so the next shiny tool is just Tuesday."
- **Image idea:** A gate (security) opening onto a toolshed (the tools) — order matters.

---

## Section 2.1 — Security, Governance, and Responsible AI Use `[JS]` (10 slides, ~30 min, opens the block)

### Slide 2.1.1 — The gap between what we do and what we know (hook)
- Show-of-hands: "Who's pasted a production schema, a query plan, or real data into
  ChatGPT? Keep your hand up if you know exactly what that vendor may do with it."
- That gap — between what we do and what we know — is the whole section.
- Posture: not "AI is dangerous, be afraid," not "it's fine, ship it." **Informed control.**
- **Image idea:** Two columns "what we do" vs "what we know," a visible gap between them.

### Slide 2.1.2 — Why security first (the meta-point — say it out loud)
- DBAs are paid to be paranoid; that instinct is correct, so we lead here.
- A vendor who demos the cool feature before the data-handling story is a vendor to
  distrust — don't be that person to your own org. (Callback to 1.5: lead with risk.) `[→ 1.5]`
- **Image idea:** A "data-handling" slide placed *in front of* a "cool demo" slide.

### Slide 2.1.3 — Data leakage: the chain of custody
- Prompt leaves your machine → vendor servers → may be **logged**, **retained**,
  **human-reviewed**, and on consumer tiers **used to train** future models.
- Key line: "The question isn't 'is the data sensitive?' It's 'would I email this to
  a stranger at a company I don't have a contract with?' On the free tier, that's the action."
- **Image idea:** A prompt traveling machine → cloud → log/retain/train icons.

### Slide 2.1.4 — What's actually at risk (it's not just PII)
- **PII** (the obvious one), **schema as IP** (your data model is a competitive
  asset), **embedded credentials** in sample connection strings, **business logic**
  in the procs you paste "for refactoring."
- The subtle one: **inference** — even "anonymized" rows leak distributions,
  cardinalities, and naming that say more than you intended.
- **Image idea:** Five risk chips around a pasted query: PII / schema / creds / logic / inference.

### Slide 2.1.5 — The spectrum: consumer ↔ enterprise ↔ local
- **Consumer cloud** (free ChatGPT/Claude/Gemini): best models, worst data terms —
  assume retention + possible training unless opted out.
- **Enterprise cloud** (ChatGPT Enterprise, Claude for Work, Copilot, Azure OpenAI /
  Foundry): same/near-same models, contractual boundaries (no training on your data,
  residency, admin controls, audit) — the sweet spot for most orgs.
- **Local / self-hosted** (Ollama, llama.cpp, local Phi/Llama): data never leaves;
  weaker models, your hardware, your ops burden.
- Key line: "You're trading capability for control — match the tier to the task's
  sensitivity, don't pick one tier for everything."
- **Image idea:** A slider from "consumer (max capability)" to "local (max control)."

### Slide 2.1.6 — Deployment options, named
- **Microsoft Foundry / Azure OpenAI** — enterprise cloud inside your tenant's
  boundaries; the natural fit for a Microsoft-data shop, and where SQL Server's own
  AI features point. `[Azure]`
- **Ollama** — the easy on-ramp to local models (`ollama run llama3` = private). `[Non-MS]`
- **Local LLMs (Phi, Llama, Mistral)** — "good enough" for many drafting/explaining
  tasks, fully offline.
- **Private/VNet deployments** — for regulated shops: the model endpoint inside your perimeter.
- **Image idea:** Four labeled boxes along the consumer→local spectrum.

### Slide 2.1.7 — Corporate AI usage policy: what to advocate for (the AUP checklist)
- **Approved tools + tiers** (which assistants/licenses — and which are banned).
- **Data classification rules** — what may *never* be pasted (PII, PHI, secrets,
  regulated data), regardless of tier.
- **Human-in-the-loop mandate** — AI output is reviewed before it touches prod. Always.
- **No prod write access for AI tools** — read-only by default; guardrails on
  anything that executes. `[→ 6.2]`
- **Logging/accountability** — who used what, for what; who owns the outcome.
- The shadow-IT reality: a policy that only says "no" creates invisible risk — give
  people a *sanctioned* path or they'll use the unsanctioned one.
- **Image idea:** A printable one-page AUP checklist (handout / lead-magnet slide).

### Slide 2.1.8 — Compliance: classify first, then choose the tier
- Common thread: HIPAA / PCI-DSS / GDPR all govern **where regulated data may go and
  who may process it.** A consumer LLM is an unvetted third-party processor.
- **HIPAA** → need a BAA (consumer tiers don't offer one; enterprise/Azure can).
- **PCI-DSS** → cardholder data near an LLM prompt is a scope explosion.
- **GDPR** → residency + right-to-erasure + "no training on personal data"; check the
  DPA and where inference runs.
- Takeaway: **classify the data first; the tool decision falls out of that.**
- **Image idea:** A data-classification stamp feeding into a tier choice.

### Slide 2.1.9 — Trust but verify (the principle for the whole day)
- LLM output is a **starting point, not a final answer** — a confident junior who
  never says "I don't know." For a DBA, the cost of a wrong index hint or a broken
  `MERGE` is paid in production, not the chat window.
- Set it now so every later demo lands the same way: *we generate, then we verify.*
  (Threads into 3.1, 5.1.) `[→ 3.1]` `[→ 5.1]`
- And verify the guardrails *you* build: "I run ~90 governance checks across my own
  AI tooling; prepping this talk I found one whose blocking rule had been silently
  dead for weeks — it looked like a guardrail and protected nothing." `[→ 6.2]`
- > War-story line: "The most dangerous guardrail is the one everyone believes is
  working. Test that your 'no' actually fires — mine didn't, and I'd have sworn it did."
- **Image idea:** A "✓ verify" stamp over an AI answer; a small dead-guardrail inset.

### Slide 2.1.10 — ▶ DEMO (candidate) + transition
- **Candidate demo (decide in/out — section is dense):** a network inspector showing
  the *same* prompt to (a) consumer ChatGPT in-browser vs (b) a local Ollama model —
  cloud request leaves with the full payload vs **zero outbound** for Ollama. Keep
  <4 min or use pre-captured screenshots.
- Closing line: "Responsible AI use isn't a tax that slows you down — it's the thing
  that lets you say *yes*, safely, with security nodding instead of blocking."
- Transition: "You know what's safe — now let's look at what's already *on your
  machine*." → Kevin's 2.2.
- **Image idea:** Split network capture: full payload out vs nothing out.

---

## Section 2.2 — Built-In AI Features: What's Already in Your Toolkit `[KF]` (7 slides + 2 demos, ~15–18 min)

> Goal of 2.2: show that AI is **already built into the tools they use** — SSMS,
> VS Code, the Azure portal — plus where Microsoft is heading (Fabric IQ). Demo plan:
> a **VS Code + Claude Code** demo (Linux), and an **SSMS Copilot** demo (Azure
> Windows VM, latest SSMS). Everything else is discussion.

### Slide 2.2.0 — The AI is already on your machine
- You don't have to go buy a new product — Copilot/agents are increasingly
  **built into** SSMS, VS Code, and the Azure portal.
- Today's lay of the land: Microsoft-native assistants (SSMS, VS Code mssql,
  Azure portal) + agentic tools you bring into the editor (e.g., Claude Code).
- **Image idea:** Three familiar app icons (SSMS, VS Code, Azure portal) each with
  a small "AI" spark already inside.

### Slide 2.2.1a — What's in the latest SSMS
- The latest SSMS ships **GitHub Copilot in SSMS** `[Preview]`. *(It replaced the
  earlier "Copilot in SSMS" from SSMS 21, which used an Azure OpenAI endpoint;
  the current one signs in with **GitHub Copilot**.)* Install via the **AI
  Assistance** workload in the Visual Studio Installer.
- It's **schema-aware** — it knows the objects (tables, columns, indexes, views)
  of the database your active editor is connected to.
- Capabilities: sidecar **chat** + **inline chat** (`Alt+/`); code assistance via
  slash commands (`/doc`, `/explain`, `/fix`, `/optimize`); **completions** + Next
  Edit Suggestions; reference the **results grid / execution plan**; **custom &
  database instructions**; a **model picker** (bring your own model). `[Preview]`
- **Image idea:** SSMS with the Copilot sidecar open, a natural-language prompt
  turning into T-SQL.

### Slide 2.2.1b — Governance built in (callback to 2.1)
- Microsoft states SSMS/Copilot **don't retain** prompts, responses, or info about
  your database/environment; queries run under **your login and permissions** (no
  separate Copilot permissions). `[Preview]`
- Still: verify before you run, and don't paste secrets — the 2.1 rules apply. `[→ 2.1]`
- **Image idea:** A small "your login · your permissions · nothing retained" badge.

### Slide 2.2.1c — ▶ DEMO: GitHub Copilot in SSMS (Azure Windows VM)
- On the Azure Windows VM with the latest SSMS, connected to a database:
  NL→T-SQL ("top-selling products…"), `/fix` a broken query, `/explain` a query,
  environment Q&A ("is there blocking right now?", "what's the largest table?"),
  optionally a **Mermaid** ER diagram of the schema.
- **Prep:** Azure Windows VM, latest SSMS + AI Assistance workload, signed in to
  GitHub Copilot, connected to a demo DB (AdventureWorks, an Azure SQL DB, or the
  Wake County container if reachable).
- **Image idea:** "to the VM" interstitial / SSMS screenshot.

### Slide 2.2.2 — VS Code: the Microsoft-native path
- VS Code = **GitHub Copilot** + **Copilot Chat**, plus the **MSSQL extension's
  `@mssql` chat participant** `[GA]` — schema-aware chat, inline completions, and
  an **Agent Mode** where Copilot uses the extension's tools to connect, list
  databases, and run queries (with your confirmation).
- Database-specific helpers: Schema Designer with Copilot, query-optimizer
  assistant, security analyzer, test-data generator, NL2SQL, and a **Data API
  builder** that can expose tables as REST/GraphQL/**MCP** endpoints (foreshadows
  Block 5's MCP). `[GA]` / Schema Designer Copilot `[Preview]`
- *Discussion, not a live demo here* — this is the Microsoft-native option; the
  live VS Code demo (next) uses an agentic assistant.
- **Image idea:** VS Code with the `@mssql` chat participant connected to a DB.

### Slide 2.2.3 — ▶ DEMO: Claude Code in VS Code (Linux)
- Beyond autocomplete: **agentic** assistants that read/edit files across a repo,
  run commands, and use **MCP servers** for live context. **Claude Code**
  (Anthropic) `[Non-MS]` integrates into VS Code and runs on Linux/macOS/Windows.
- For DB work: edit/refactor `.sql` files, reason over a whole project, and
  connect to a **SQL MCP server** so the agent has your real schema/data context
  (directly ties to Block 5). `[→ Block 5]`
- **▶ DEMO (Linux machine, VS Code + Claude Code):** build/refactor a stored
  procedure across files, or have it use an MCP server pointed at the Wake County
  SQL container for schema-aware help.
- **Presenter note:** Claude Code also appears in **2.3** (CLI/standalone tools) —
  coordinate so you don't double-cover; here the angle is *agentic AI inside your
  editor*, vs *AI from the terminal* in 2.3. `[→ 2.3]`
- **Image idea:** VS Code with Claude Code making multi-file edits + an MCP panel.

### Slide 2.2.4 — AI in the Azure portal
- **Microsoft Copilot in Azure with Azure SQL Database** `[Azure · Preview]` —
  conversational self-help in the portal: "why was my database unavailable?",
  "what do the wait stats look like?", "am I hitting resource limits?". It draws on
  DMVs, Query Store, catalog views, and docs.
- Plus **Copilot skills in Azure SQL Database** (NL2SQL in the query editor,
  preview/limited) and **Copilot for SQL database in Fabric** `[Preview]` (code
  completion, Fix/Explain, chat pane).
- *Discussion only.* The point: the **managed** platforms get AI in the portal,
  not just in client tools.
- **Image idea:** Azure portal Copilot answering "why was my DB slow?" with a
  wait-stats explanation.

### Slide 2.2.5 — Fabric IQ: the direction of travel
- **Fabric IQ** `[Preview]` (introduced Nov 2025) is a new Microsoft Fabric
  workload that unifies **business semantics** — ontology, graph, semantic models,
  and data/operations **agents** — so AI reasons over your data with consistent
  meaning, not raw tables. It's part of "Microsoft IQ" (Fabric IQ / Work IQ /
  Foundry IQ).
- Why a data pro should care: the frontier is **grounding agents in your business
  vocabulary and relationships** (e.g., *Order → Shipment → Sensor → Cold-chain
  breach*). Forward-looking — not something you'd demo today.
- **Image idea:** Layers: raw tables → a semantic/ontology layer → an AI agent
  asking a business question.

---

## Section 2.3 — Standalone AI Tools for Data Professionals `[JS]` (6 slides + demo, ~15 min)

### Slide 2.3.1 — There is no "best AI tool" (hook)
- "There's the best tool *for this task, at this sensitivity, in this context*.
  Anyone selling one tool that wins everything is selling something."
- 2.2 covered what's *baked in*; this covers what you go *get* — and how to choose.
- **Image idea:** A row of tool logos with a big "?" — replaced later by a decision tree.

### Slide 2.3.2 — Chat assistants: ChatGPT, Claude, Gemini
- **Shared strengths:** explaining code, drafting boilerplate T-SQL, translating
  dialects, rubber-ducking a design.
- **Shared blind spots:** no knowledge of *your* schema; confident wrong answers on
  version-specific syntax; inventing DMVs / system views / functions that don't exist.
- Differentiators (don't over-index — they leapfrog monthly): context-window size,
  reasoning depth, and **which one your org has at the enterprise tier** — the real
  tiebreaker. `[→ 2.1]`
- Key line: "Pick the model your company already pays for at the enterprise tier. A
  slightly better model on the consumer tier is a worse choice once you remember 2.1."
- **Image idea:** Three chat logos with a shared "doesn't know your schema" tag.

### Slide 2.3.3 — Specialized editors: Cursor, Windsurf
- AI-native *editors* (VS Code forks) where the assistant sees your whole project,
  edits across files, and runs in a tight loop — a step beyond a chat window. `[Non-MS]`
- Shine for data folks: multi-file SQL projects, migration scripts, a repo of
  procs/views — anything needing more than one file in view.
- The catch: now the tool has your codebase — same 2.1 questions (data boundary,
  model backend, enterprise vs consumer). `[→ 2.1]`
- **Image idea:** An editor seeing a whole project tree vs a single-snippet chat box.

### Slide 2.3.4 — CLI agents: Claude Code, GitHub Copilot CLI, aider
- Power-user tier: the assistant lives in your terminal, reads/writes files, runs
  commands, works **agentically** (plans → acts → checks).
- **Claude Code** `[Non-MS]` (home turf): agentic, MCP-aware, great for "build me a
  thing" and multi-step DB tasks. **Copilot CLI** if you're in the GitHub ecosystem.
  **aider** `[Non-MS]`: open-source, model-agnostic, pairs with git — bring your own
  (incl. local) model. `[→ 2.1]`
- Honest caveat: highest ceiling, steepest learning curve, most capable of doing
  damage — which is exactly why guardrails (6.2) matter. `[→ 6.2]`
- **Image idea:** A terminal with an agent planning → editing → running.

### Slide 2.3.5 — The decision framework (the write-it-down slide)
- Ask four questions, in order:
  1. **Sensitivity** — what data touches this task? (Sets tier/locality from 2.1;
     this gate comes first and can veto everything below.) `[→ 2.1]`
  2. **Scope** — one snippet (chat), a whole project (editor), or a multi-step
     build/automation (CLI agent)?
  3. **Context the tool needs** — does it need to *see* your schema/repo? If yes,
     you've left the chat window.
  4. **Loop speed** — copy-paste is fine occasionally; 40×/day graduates to an
     editor or CLI tool.
- Key line: "Sensitivity first, always — it can disqualify the tool you wanted, so
  ask it before you fall in love."
- **Image idea:** A 4-step decision tree, sensitivity at the top as a gate.

### Slide 2.3.6 — ▶ DEMO: schema-blind vs context-aware
- Same prompt, same task (e.g., "write a proc to find/report duplicate rows by
  business key on this table") across 2–3 tools — a chat assistant vs a CLI/editor
  agent that can see the schema (~4 min).
- Payoff: the schema-blind tool *guesses* column names; the context-aware tool gets
  them right — previews the MCP punchline in 5.2 without stealing it. `[→ 5.2]`
- **Backup:** pre-captured outputs side by side.
- **Image idea:** Two outputs side by side — guessed columns vs correct columns.

---

## Section 2.4 — Evaluating New AI Tools as They Emerge `[JS]` (5 slides, ~10 min, closes the block)

### Slide 2.4.1 — If I taught you tools, I've failed (hook)
- "Everything in 2.3 has a shelf life measured in months. Let me teach you the
  *test* instead — so the next shiny thing gets evaluated, not just adopted or feared."
- **Image idea:** A tool logo with a "best before: 3 months" sticker.

### Slide 2.4.2 — The 6-question evaluation checklist (the handout)
1. **Data handling** — where does my data go? Enterprise tier with no training,
   DPA/BAA, residency? *If this fails, stop here.* `[→ 2.1]`
2. **Fit to task & context** — solves a real, frequent pain, and can it see the
   context it needs (schema, repo, docs)? `[→ 2.3]`
3. **Accuracy & verifiability** — can I check its output? Does it show its work?
4. **Integration cost** — fits my workflow (SSMS, VS Code, CLI, Azure) or demands a
   new one? Switching cost is real cost.
5. **Vendor viability** — will this exist in 18 months? Funding, adoption, cadence,
   OSS vs VC-burning-cash.
6. **Lock-in & exit** — if it dies or triples in price, how hard to leave? Open
   standards (e.g., MCP) and model-agnostic tools lower this. `[→ 5.2]`
- Key line: "Adoption is easy. Reversal is expensive. Score the exit before the features."
- **Image idea:** A printable one-page checklist (the lead-magnet slide).

### Slide 2.4.3 — Questions to ask vendors / OSS communities
- **Vendors:** "Do you train on my data on my tier?" · "Show me the DPA/BAA." ·
  "Where does inference run?" · "Data-deletion guarantee?" · "What happens to my
  data if I cancel?" — watch *how* they answer (crisp = mature; hand-wavy = not).
- **OSS:** last commit date? issue response time? bus factor (one maintainer or a
  team)? security-disclosure process? A vibrant 3-year repo beats a flashy README + Discord.
- **Image idea:** Two columns — vendor questions vs OSS questions.

### Slide 2.4.4 — Keeping up without drowning
- Curate a *small* set of high-signal sources; ignore the firehose.
- Source types (name specifics near the event): 1–2 changelogs for tools you use;
  1–2 honest independent practitioners (not hype accounts); the community your peers
  are in (PASS/SQL community, relevant Discords/subreddits, the hallway track).
- Cadence: a 30-min weekly skim beats daily doom-scrolling. You don't need to adopt
  the new thing the week it ships — you need to *know it exists* and have the
  checklist ready.
- **Image idea:** A small curated feed vs a firehose, the firehose crossed out.

### Slide 2.4.5 — Block 2 wrap + transition
- "You don't have to chase every tool. You need a security stance, a decision
  framework, and a checklist — then the next shiny thing is just Tuesday."
- Next we start *using* this stuff: prompt engineering (Block 3 / 3.1). `[→ 3.1]`
- **Image idea:** Three takeaway chips — stance · framework · checklist — with an
  arrow to Block 3.

---

## Section 2 wrap (1 slide, ~1 min)

### Slide 2.W — Takeaways
- **Safe first:** classify the data, match the tier, verify the output, write the AUP.
- **Tools, two flavors:** native assistants (SSMS Copilot, `@mssql`, Azure portal)
  and agentic assistants (Claude Code et al.) — both have a place.
- **Durable method:** the 4-question pick framework + the 6-question eval checklist
  outlive any specific tool.
- Keep 2.1's rules in view all day: don't paste secrets; **verify** everything.
- **Image idea:** A 2×2 (native vs agentic · in-editor vs in-portal) with tools placed,
  the AUP + eval checklists pinned beside it.

---

## Appendix — Presenter prep & fact-check (not slides)

### Demo prep
- **2.1 network demo (optional, JS):** decide live-vs-screenshots given section
  density (leaning screenshots). A browser devtools / Fiddler / Wireshark capture of
  the same prompt to consumer ChatGPT vs local Ollama — full payload out vs zero out.
  Pre-capture both flows as backup. Keep <4 min or cut to screenshots.
- **2.2 SSMS demo (KF, Azure Windows VM):** provision a Windows VM; install the
  **latest SSMS** + the **AI Assistance** workload (Visual Studio Installer); sign in
  to **GitHub Copilot**; connect to a demo DB. Have 3–4 prompts ready (NL2SQL, /fix,
  /explain, an environment question).
- **2.2 Claude Code demo (KF, Linux laptop):** VS Code + Claude Code extension,
  signed in; optionally a SQL **MCP server** pointed at the Wake County container
  (`src/infra/docker/`) so the agent is schema-aware. One concrete task (build/refactor
  a proc) staged.
- **2.3 side-by-side demo (JS):** same prompt across 2–3 tools (a pure-chat assistant
  vs Claude Code/an editor that can see the schema). Reuse the demo task/schema across
  2.3 / 5.1 for continuity. Pre-capture outputs.

### Fact-check (verify before delivery — these move fast)
- **2.1 vendor terms:** pull *current* data-retention / training-opt-out terms for
  the named consumer tiers near the event (they change — don't quote stale terms).
  BAA/DPA availability differs by tier.
- **GitHub Copilot in SSMS** — `[Preview]`, in **SSMS 22** (latest), via the AI
  Assistance workload; it **replaced** the SSMS 21 "Copilot in SSMS" (Azure OpenAI
  endpoint). *Note: Block 4's D.6 references "GitHub Copilot in SSMS 21 [GA]" — update
  to SSMS 22 / Preview for consistency.*
- **MSSQL extension `@mssql`** for VS Code (chat, inline, **Agent Mode** tools) — GA
  (ver17 docs); Schema Designer + Copilot is `[Preview]`.
- **Claude Code / Cursor / Windsurf / aider** — third-party `[Non-MS]`; confirm
  naming/availability near the event.
- **Microsoft Copilot in Azure with Azure SQL Database** + Azure SQL query-editor
  **Copilot skills** — `[Preview]`. **Copilot for SQL database in Fabric** — `[Preview]`.
- **Fabric IQ** — `[Preview]`, a Microsoft Fabric workload (ontology, plan, graph,
  data/operations agents, semantic models); part of Microsoft IQ.

### Coordination with Kevin
- 2.2 (Copilot, IDE/SSMS angle) vs 2.3 (chat + CLI angle) — Claude Code appears in
  both; keep 2.2 = *agentic inside the editor*, 2.3 = *AI from the terminal*.
- The AUP checklist (2.1) + the eval checklist (2.4) are lead-magnet candidates —
  fold into the "AI Adoption Starter Kit" handout alongside 6.4's roadmap template.
