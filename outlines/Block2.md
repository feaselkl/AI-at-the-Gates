# Block 2 — The AI Tooling Landscape + Security & Governance (2.2 only)

**Slide-deck outline (build notes, not finished slides).**
Part of *AI at the Gates: The DBA's Guide to Surviving in an LLM World*.

- **Duration:** Block 2 is 75 min (10:15 – 11:30). **This file covers 2.2 only**
  ("Built-In AI Features"), ~15–18 min. 2.1, 2.3, 2.4 are outlined separately /
  by a co-presenter.
- **Audience:** DBAs, data engineers, database developers. After 2.1 they've heard
  the governance rules (don't paste secrets, verify output) — reinforce them here.
- **Goal of 2.2:** Show that AI is **already built into the tools they use** —
  SSMS, VS Code, the Azure portal — plus where Microsoft is heading (Fabric IQ).
- **Your demo plan (reflected below):** a **VS Code + Claude Code** demo on your
  Linux machine, and an **SSMS Copilot** demo on an Azure Windows VM with the
  latest SSMS. Everything else in 2.2 is discussion, no demo.

---

## How to read this outline

Per slide: **talking points**, an **image idea**, and demo callouts (`▶ DEMO`).
Because 2.2 is a tooling survey, claims carry a light status tag — `[GA]`,
`[Preview]`, `[Non-MS]` (third party), `[Concept]` — verified against Microsoft
Learn (June 2026). A presenter **fact-check** is in the appendix.

---

## Section 2.2.0 — Opener (1 slide, ~1 min)

### Slide 2.2.0 — The AI is already on your machine
- You don't have to go buy a new product — Copilot/agents are increasingly
  **built into** SSMS, VS Code, and the Azure portal.
- Today's lay of the land: Microsoft-native assistants (SSMS, VS Code mssql,
  Azure portal) + agentic tools you bring into the editor (e.g., Claude Code).
- **Image idea:** Three familiar app icons (SSMS, VS Code, Azure portal) each with
  a small "AI" spark already inside.

---

## Section 2.2.1 — SSMS: GitHub Copilot in SSMS (2 slides + demo, ~6 min)

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
- Still: verify before you run, and don't paste secrets — the 2.1 rules apply.
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

---

## Section 2.2.2 — VS Code: the Microsoft-native path (1 slide, discussion, ~3 min)

### Slide 2.2.2 — GitHub Copilot + the MSSQL extension
- VS Code = **GitHub Copilot** + **Copilot Chat**, plus the **MSSQL extension's
  `@mssql` chat participant** `[GA]` — schema-aware chat, inline completions, and
  an **Agent Mode** where Copilot uses the extension's tools to connect, list
  databases, and run queries (with your confirmation).
- Database-specific helpers: Schema Designer with Copilot, query-optimizer
  assistant, security analyzer, test-data generator, NL2SQL, and a **Data API
  builder** that can expose tables as REST/GraphQL/**MCP** endpoints (foreshadows
  Block 5's MCP). `[GA]` / Schema Designer Copilot `[Preview]`
- *Discussion, not a live demo here* — this is the Microsoft-native option; your
  live VS Code demo (next) uses an agentic assistant.
- **Image idea:** VS Code with the `@mssql` chat participant connected to a DB.

---

## Section 2.2.3 — VS Code: agentic assistants (1 slide + demo, ~5 min)

### Slide 2.2.3 — ▶ DEMO: Claude Code in VS Code (Linux)
- Beyond autocomplete: **agentic** assistants that read/edit files across a repo,
  run commands, and use **MCP servers** for live context. **Claude Code**
  (Anthropic) `[Non-MS]` integrates into VS Code and runs on Linux/macOS/Windows.
- For DB work: edit/refactor `.sql` files, reason over a whole project, and
  connect to a **SQL MCP server** so the agent has your real schema/data context
  (directly ties to Block 5).
- **▶ DEMO (your Linux machine, VS Code + Claude Code):** e.g., build/refactor a
  stored procedure across files, or have it use an MCP server pointed at the Wake
  County SQL container for schema-aware help.
- **Presenter note:** Claude Code also appears in **2.3** (CLI/standalone tools) —
  coordinate so you don't double-cover; here the angle is *agentic AI inside your
  editor*, vs *AI from the terminal* in 2.3.
- **Image idea:** VS Code with Claude Code making multi-file edits + an MCP panel.

---

## Section 2.2.4 — Azure Portal: Copilot in Azure SQL (1 slide, discussion, ~2 min)

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

---

## Section 2.2.5 — Fabric IQ: the direction of travel (1 slide, discussion, ~2 min)

### Slide 2.2.5 — Where Microsoft is heading: semantics for AI
- **Fabric IQ** `[Preview]` (introduced Nov 2025) is a new Microsoft Fabric
  workload that unifies **business semantics** — ontology, graph, semantic models,
  and data/operations **agents** — so AI reasons over your data with consistent
  meaning, not raw tables. It's part of "Microsoft IQ" (Fabric IQ / Work IQ /
  Foundry IQ).
- Why a data pro should care: the frontier is **grounding agents in your business
  vocabulary and relationships** (e.g., *Order → Shipment → Sensor → Cold-chain
  breach*) for trustworthy answers and actions. Forward-looking — not something
  you'd demo today.
- **Image idea:** Layers: raw tables → a semantic/ontology layer → an AI agent
  asking a business question.

---

## Section 2.2 wrap (1 slide, ~1 min)

### Slide 2.2.W — Takeaways
- AI is **already in the tools you use** — SSMS (GitHub Copilot), VS Code
  (Copilot + `@mssql`, and agentic tools like Claude Code), and the Azure portal.
- Two flavors to know: **native assistants** (schema-aware, in-tool) and
  **agentic assistants** (edit files, run commands, use MCP). Both have a place.
- Keep 2.1's rules in view: don't paste secrets; **verify** the output.
- Next: 2.3 (standalone tools — ChatGPT/Claude/Cursor/Claude Code CLI/aider) and
  2.4 (how to evaluate new tools).
- **Image idea:** A 2×2 — native vs agentic, in-editor vs in-portal — with the
  tools placed.

---

## Appendix — Presenter prep & fact-check (not slides)

### Demo prep
- **SSMS demo (Azure Windows VM):** provision a Windows VM; install the **latest
  SSMS** + the **AI Assistance** workload (Visual Studio Installer); sign in to
  **GitHub Copilot**; connect to a demo DB. Have 3–4 prompts ready (NL2SQL, /fix,
  /explain, an environment question).
- **Claude Code demo (your Linux laptop):** VS Code + the Claude Code extension,
  signed in; optionally a SQL **MCP server** pointed at the Wake County container
  (`src/infra/docker/`) so the agent is schema-aware. Have one concrete task
  (build/refactor a proc) staged.

### Fact-check (verify before delivery — these move fast)
- **GitHub Copilot in SSMS** is `[Preview]`, in **SSMS 22** (latest), via the AI
  Assistance workload; it **replaced** the SSMS 21 "Copilot in SSMS" (which used
  an Azure OpenAI endpoint). *Note: Block 4's D.6 references "GitHub Copilot in
  SSMS 21 [GA]" — update that to SSMS 22 / Preview for consistency.*
- **MSSQL extension `@mssql`** for VS Code (chat, inline, **Agent Mode** tools) —
  GA (ver17 docs); Schema Designer + Copilot is `[Preview]`.
- **Claude Code** — Anthropic, third-party; VS Code integration; cross-platform;
  MCP-capable. `[Non-MS]`
- **Microsoft Copilot in Azure with Azure SQL Database** and the Azure SQL query-
  editor **Copilot skills** — `[Preview]`. **Copilot for SQL database in Fabric** —
  `[Preview]`.
- **Fabric IQ** — `[Preview]`, a Microsoft Fabric workload (ontology, plan, graph,
  data/operations agents, semantic models); part of Microsoft IQ.
