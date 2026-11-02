# Portland deck: slide text and speaker notes

For Jonathan's generator. This is the full text-and-notes pass on every slide of the rebuilt
deck, in the new running order from `portland-rebuild-design.md` (read that first for the order,
cuts, and new slides). Old slide numbers refer to the current master deck,
`scenic-city-aigates-precon.pptx`, with the fixes in `deck-changes-2026-11.md` applied; those
fixes still need porting into the generator source.

For each slide:
- **Visible text edits** quote the current text exactly (including the deck's existing
  em-dashes and curly quotes, so they can be found) and give the replacement. "delete" removes
  the box. New and merged slides give their full **Visible text** instead.
- **Notes** are complete replacement speaker notes. Every slide has them, including slides that
  had none.
- **Check** lines are for a presenter to confirm in rehearsal. They are collected at the end.

The "AI AT THE GATES: ..." and "SLIDE nn" footer boxes are left alone; the generator renumbers them.

---

## Section 0: Opening

### 0.1 (old 1): AI at the Gates (title)

**Visible text edits:**
- [TextBox 1] "SCENIC CITY SUMMIT 2026" -> "DAY OF DATA PORTLAND 2026"
- [TextBox 7] "JONATHAN STEWART + KEVIN FEASEL · SCENIC CITY SUMMIT 2026" -> "JONATHAN STEWART + KEVIN FEASEL · DAY OF DATA PORTLAND 2026"
- [TextBox 5] subtitle "Full-Day Precon · The DBA's Guide to Surviving in an LLM World" stays as is; it names no event.

**Notes:**
Welcome to AI at the Gates, the DBA's guide to surviving in an LLM world. This is a full-day pre-con for people who work with databases and have little or no AI background, so nobody needs prior experience with models. Kevin and Jonathan are presenting together. Cover the room logistics here: when the breaks and lunch are, and where to get the slides and the demo code. Then go to introductions.

**Check:** Friday's break and lunch times (spec open item). The slides-and-code link is github.com/feaselkl/AI-at-the-Gates (also on 6.10).

### 0.2 (old 2): About Me.

**Visible text edits:**
- [TextBox 4] "I help data teams adopt AI without getting burned — and I build the tooling I'm about to show you." -> "I help data teams adopt AI without getting burned, and I build the tooling I'm about to show you."

**Notes:**
I'm Jonathan Stewart, principal analytics consultant at Sound BI. My work is helping data teams adopt AI without getting burned. I founded the SQLBites community, which trains new data practitioners. I've done production migrations to Fabric in healthcare, finance, retail, and manufacturing, and I've given hundreds of technical talks. Keep this under a minute. You'll see me this afternoon for the agents section and the close on talking to leadership.

**Check:** Jonathan confirms "the tooling I'm about to show you" still fits now that most of the old build-your-own-tools slides are cut.

### 0.3 (old 3): The Actual Presenter.

**Visible text edits:** none

**Notes:**
Kevin Feasel, Microsoft MVP, proprietor of Catallaxy Services, LLC. Lead contributor to Curated SQL (curatedsql.com) and president of TriPASS, the Triangle Area SQL Server Users Group (meetup.com/tripass). Author of PolyBase Revealed (Apress, 2020) and Finding Ghosts in Your Data (Apress, 2022). Lives in Raleigh, NC. The title plays off the slide before it; keep this to 30 seconds. The morning covers how models work, vectors, and vectors in SQL Server, with RAG right after lunch.

### 0.4 (new): What you'll leave with

**Visible text:**
What you'll leave with
- What vector data is, and why it isn't scary.
- How to store and search vectors in SQL Server, and a plan for a pilot in your own shop.
- How to work with AI agents, and where they go wrong.
- How to build a basic RAG system over your own documents.
- How to talk to leadership about all of it: what's possible and what isn't.

**Notes:**
These are the five things the day is built around. If a slide doesn't serve one of them, it isn't in the deck. The first two take the morning: what vectors are, then working with them in SQL Server, ending with a step-by-step plan for a pilot. The order of the day differs a little from this list: RAG comes right after lunch, before agents, because it builds directly on the vector material. The last section is about making the case to leadership, and it uses what you see in the demos today as its evidence.

### 0.5 (new): The ledger

**Visible text:**
The ledger
Visual: an empty two-column table, headed "Worked" and "Broke".
Body: "Every demo today adds to this. At the end of the day, it's your evidence."

**Notes:**
Every demo today ends with a row or two on this ledger, in one column or both. Only things that happen on screen today go in: no industry statistics, no predictions, no stories from somewhere else. We show it at the end of sections 1, 3, 4, and 5, with that section's new rows highlighted. In the last section, the whole ledger goes on screen and we use it to answer the question every boss is asking: can we replace people with this? First, though, how these models work.

---

## Section 1: How these models work, just enough

### 1.0 (old 4): How these models work (divider)

**Visible text edits:**
- [TextBox 4] "FOUNDATIONS" -> "HOW THESE MODELS WORK"
- [TextBox 1] "01", [TextBox 3] "CHAPTER ONE", and [TextBox 6] "The basics of how generative AI works" stay; this is still the first numbered section.

**Notes:**
Section 1 covers just enough about how language models work to make the rest of the day make sense. No SQL Server in this section: everything runs in a browser or on a small local model. The ideas to land are that a model predicts the next token, over and over; that it reads tokens and has a limited context window; and that it can be fluent, confident, and wrong. It ends with the temperature demo and the first rows on the ledger.

### 1.1 (old 12): You don't build models. You own the data they use.

**Visible text edits:** none

**Notes:**
This frames the day. Nobody here needs to train a model. What you own is the data models read and the data they produce: storing it, securing it, serving it, and querying it. That's a data-platform job, and it's already yours. Every section today answers the same question one step further: how does the model get your context? Vectors turn your data into something a model can search. With RAG, you find the context and hand it over. With MCP, the model looks it up itself. Agents act on what they find. Next: what a model actually does with the text you give it.

### 1.2 (old 9): Generation is next-token prediction, repeated

**Visible text edits:** none

**Notes:**
An LLM does one thing. Given everything so far, it predicts the next token, which is roughly a word or a piece of one (tokens get their own slide shortly). It appends that token and predicts again. A paragraph is that loop run many times. Hold on to this idea, because it explains most of what you'll see today. The model sounds fluent because it has seen a lot of fluent text. It can also be confidently wrong, because the likeliest next token isn't checked against anything. On the next slide, the room does the predicting.

### 1.3 (old 10): Guess the Next Word

**Visible text edits:** none

**Notes:**
No model on screen. Ask the room to finish the line. Most people will call out "human events." That's all a model does: predict the likeliest next token, over and over. The room got it right because it has seen that sentence many times; so has the model. Nobody looked anything up. The answer came from familiarity with the pattern, and that's also why a model can be confidently wrong when the pattern points somewhere false. We come back to that two slides from now.

**Check:** Kevin confirms this reading of the slide (the spec marks it as "my reading; Kevin to confirm").

### 1.4 (old 15): Models see tokens, not characters or words

**Visible text edits:**
- [TextBox 4] "Before anything else, text is split into tokens--subword chunks--and each token maps to a number. It's just another encoding step, like a lookup table. Unusual words fragment into several tokens, whereas common words are one." -> "Before anything else, text is split into tokens (subword chunks), and each token maps to a number. It's just another encoding step, like a lookup table. Common words are one token; unusual words break into several."

**Notes:**
Before the model sees anything, text is split into tokens, and each token maps to a number. Think of it as an encoding step with a lookup table. Common words are usually a single token; unusual words break into several. Demo, about two minutes, browser only: open a tokenizer such as tiktokenizer.vercel.app, paste an ordinary sentence and watch it split, then paste an odd word or one of your own long table names and watch it fragment. Tokens matter on the next slide, because that's the unit the context window is measured in.

### 1.5 (old 16): How many tokens it can hold in mind at once

**Visible text edits:** none

**Notes:**
The context window is the model's working memory, measured in tokens: your prompt, whatever you paste in, and the conversation so far. Go past it and the start gets cut off or forgotten. Bigger windows cost more. The DBA analogy on the slide is a batch or buffer: what fits before you spill to disk. This is why choosing what the model sees comes up all day. RAG, in section 4, is a way to fill a limited window with only the passages that answer the question. Drop this slide if the section is running long.

### 1.6 (old 17): Fluent, confident, and sometimes wrong

**Visible text edits:**
- [TextBox 4] "An LLM learns patterns of language, not a database of verified facts. So it can produce fluent, confident, wrong answers ('hallucinations') simply by predicting plausible next tokens. Never trust output blindly. Verify your results." -> "An LLM learns patterns of language, not a database of verified facts. So it can produce fluent, confident, wrong answers ('hallucinations') simply by predicting plausible next tokens. Verify your results."

**Notes:**
This follows directly from next-token prediction. The model learned patterns of language. When the most plausible next tokens add up to a wrong answer, you get a wrong answer in the same confident tone as a right one. That's a hallucination. For a DBA it looks like a column that doesn't exist, or a status value that sounds right but isn't in the data. You'll see exactly that in section 5, when a model given the tables but not the real values invents a severity of 'Critical' and the query returns nothing. Verify the output every time.

### 1.7 (old 52): The most literal, overconfident junior you've ever hired

**Visible text edits:**
- [TextBox 4] "An LLM is the most literal, fastest, most overconfident junior you've ever onboarded. You already write specs for junior devs every day. Technical work needs technical prompting. That’s an engineering discipline you already have, pointed at a new target." -> "An LLM is the most literal, most overconfident junior you've ever onboarded, and the fastest. You already write specs for junior devs every day. Technical work needs technical prompting, and writing a clear spec is a skill you already have."

**Notes:**
A working model for the rest of the day: treat the LLM like a new junior. It's fast, it takes your words literally, and it sounds just as sure when it's wrong. It fills any gap in your request with a guess. You already know how to manage someone like that. Write a clear spec, give them the schema and the real values, and review what comes back. Section 5 turns this into a prompt structure and shows the before and after live. Next: the settings that change how the model picks its words.

### 1.8 (old 18): The dials that shape output

**Visible text edits:**
- [TextBox 8] "How random or creative the pick is. Low temperature → focused and repeatable; high → varied and surprising." -> "How random or creative the pick is. Low temperature is focused and repeatable; high is varied and surprising."
- [TextBox 15] "How wide a pool of candidate tokens to sample from before choosing. Narrow pool → safe; wide pool → adventurous." -> "How wide a pool of candidate tokens to sample from before choosing. A narrow pool is safe; a wide pool is adventurous."

**Notes:**
The model ranks the candidate next tokens. These two settings decide how it picks from that ranking. Temperature sets how random the pick is: at 0 it takes the top choice every time, and higher values give lower-ranked tokens a chance. Top-p sets how wide a pool of candidates it samples from. For queries and code you want low; for brainstorming, higher is fine. One recent change: reasoning models, such as the GPT-5 series in Azure OpenAI, don't accept temperature or top_p at all. The dials still apply to ordinary chat models, including the llama3.2 model in the next demo.

### 1.9 (old 19): Demo: temperature in action

**Visible text edits:**
- [TextBox 15] "Repeatable — what you want for code" -> "Repeatable: what you want for code"
- [TextBox 29] "Varied — good for brainstorming" -> "Varied: good for brainstorming"
- [TextBox 34] "Use the same model and prompt, changing only these dials." -> "Same model, same prompt. Only the temperature changes."

**Notes:**
Local and offline. File: `src/demo/block1/temperature_demo.py`. It needs Ollama running with a small chat model, `llama3.2:1b`; Harrier only does embeddings, so it can't run this one. Setup is in `src/demo/block1/README.md`; pull the model before the session.

Run `python3 src/demo/block1/temperature_demo.py`. It sends one prompt (a punny name for a taco food truck) twice at temperature 0 and twice at temperature 1.

Beats:
1. Temperature 0: both runs return the same name.
2. Temperature 1: the names differ.
3. Same model, same prompt; only the dial moved. If you're asking for a query, you want the first behavior.

If the two temperature-1 runs happen to match, rerun with `--runs 3`. Set up section 2 here: embeddings have no temperature, and the same text gives the same vector every time. Both results go on the ledger next.

### 1.10 (new): The ledger, section 1

**Visible text:**
The ledger
Two columns, "Worked" and "Broke", with both rows new (highlighted):
- Worked: At temperature 0, the same prompt gave the same answer.
- Broke: At high temperature, the same prompt gave a different answer each run.

**Notes:**
The first two rows, both from the temperature demo. Slides like "fluent, confident, and sometimes wrong" don't add rows; only what happened on screen goes on the ledger. Why is varied output under Broke? It's fine for brainstorming, but if you ask for the same query twice, you want the same query twice. The setting is under your control, at least on chat models that accept it. Next: what an embedding is, and why vector data isn't scary.

---

## Section 2: Vectors without fear

### 2.0 (new): Vectors without fear (divider)

**Visible text:**
Same layout as the 1.0 divider:
- 02
- CHAPTER TWO
- VECTORS WITHOUT FEAR
- Subtitle (optional): "What a vector is, and how similarity search works"

**Notes:**
This section is the first outcome on the list: nobody leaves afraid of vector data. Still no SQL Server. We use the browser and the same Harrier embedding model that the SQL Server demos use in section 3. By the end, everyone should be able to say what an embedding is, what "close" means for two vectors, and why vector search is usually approximate. Section 3 puts all of it in a table.


### 2.1 (old 20): An embedding turns data into a vector that captures meaning

**Visible text edits:**
- [TextBox 4] "An embedding turns a word, sentence, code snippet, or row into a fixed-length vector (a list of numbers) that captures its meaning. The magic property: similar things land near each other in that number space. This single idea powers semantic search, RAG, and recommendations." -> "An embedding turns a word, sentence, code snippet, or row into a fixed-length vector (a list of numbers) that captures its meaning. The key property: similar things land near each other in that number space. This single idea powers semantic search, RAG, and recommendations."

**Notes:**
An embedding takes a piece of data, usually text, and returns a fixed-length list of numbers. What makes those numbers useful is that things with similar meaning get similar lists, so they land near each other. A comment saying "fridge too warm" and one saying "improper cold holding" end up close even though they share no words. Semantic search, RAG, and recommendations all rest on that one property. You don't need to know what any single number means. What matters is the distance between two vectors, which is two slides from now.

### 2.2 (old 21): An embedding model produces the vector

**Visible text edits:**
- [TextBox 4] "Another neural network, known as an embedding model, produces vectors. We feed in text and get back fixed-sized vectors of floating-point numbers. It was trained so that things meaning the same end up close; you don't set the numbers by hand. You can embed text, code, and even database rows the same way." -> "A neural network called an embedding model produces vectors. We feed in text and get back fixed-size vectors of floating-point numbers. It was trained so that things that mean the same end up close; you don't set the numbers by hand. You can embed text, code, and even database rows the same way."

**Notes:**
The vectors come from an embedding model, a neural network trained so that things that mean the same land close together. Nobody sets the numbers by hand. Text goes in, and a fixed-size vector of floating-point numbers comes out. The model we use today is Harrier, running locally through Ollama, and its vectors have 1,024 dimensions. The same model produced the Projector data you're about to see and the embeddings in SQL Server in section 3, so everything you see this morning shares one embedding space.

### 2.3 (old 22): Do the two arrows point the same direction?

**Visible text edits:** none

**Notes:**
"How similar are these two things?" becomes "how close are their vectors?" Draw two arrows from the same origin. Cosine similarity asks whether they point the same way: a small angle means similar, and a right angle means unrelated. Keep it to two arrows; this isn't a math lesson. Flag one thing now, because it trips people up in section 3: SQL Server's VECTOR_DISTANCE with 'cosine' returns a distance, so a smaller number means more similar. If you're used to scores where bigger is better, flip it.

### 2.4 (old 23): DEMO: Vector Differences

**Visible text edits:** none

**Notes:**
Browser only, nothing to install: projector.tensorflow.org with its built-in word vectors. Notes are in `src/demo/block1/README.md`.

Beats:
1. Search "king" and show its nearest neighbors.
2. The analogy: king minus man plus woman lands near queen.
3. The point: directions in the space carry meaning, and nobody programmed that in. The model learned it from text.

Expect the question of how all those dimensions fit in a 3D picture. They don't: the Projector flattens them to three for display, so treat the picture as a rough map. The neighbor list is the part to trust.

**Check:** How you show king minus man plus woman in the Projector UI. I couldn't confirm it does vector arithmetic directly; if it doesn't, show it with a custom projection or describe it instead of demoing it.
**Check:** That the Projector's neighbor list is computed on the full vectors, not the 3D view, before saying "the neighbor list is the part to trust".

### 2.5 (old 24): DEMO: Wake County, NC food inspection data

**Visible text edits:** none

**Notes:**
Now our own data: Wake County, NC food-inspection violation comments, embedded ahead of time with Harrier. `src/demo/block1/embed_violations.py` writes `vectors.tsv` and `metadata.tsv` (3,000 comments by default). The files are git-ignored, so generate them before the session; the steps are in `src/demo/block1/README.md`.

Beats:
1. In the Projector, click Load, then load `vectors.tsv` and `metadata.tsv`.
2. Set Color by to severity.
3. Click a point and read its neighbors. Temperature and cold-holding comments sit together, pests are somewhere else, and cleanliness is somewhere else again.
4. Find a neighbor that shares no keywords with the comment you clicked. That's semantic search, with no database involved.

Ledger row, shown with section 3: comments about the same problem clustered together with no keywords in common.

**Check:** In rehearsal, pick and note one specific comment whose neighbors share no keywords with it, so beat 4 doesn't depend on finding one live.

### 2.6 (old 25): Why a data pro should care

**Visible text edits:**
- [TextBox 29] "Unlocks dedup, clustering, and RAG" -> "Also powers dedup, clustering, and RAG"
- [TextBox 34] "Semantic search helps us answer the question your users actually intended to ask." -> delete

**Notes:**
This is the payoff for a data person. Keyword search finds the words you typed. A search for "fridge too warm" misses every comment that says "improper cold holding," and synonyms slip through. Semantic search compares meaning, so it finds them. It gets closer to the question the user meant to ask. The same vectors also help with near-duplicate detection, grouping similar records, and RAG, which is section 4. Semantic search doesn't replace keyword search; section 3 covers combining the two.

### 2.7 (old 26): Vectors aren't the data you usually store

**Visible text edits:**
- [TextBox 34] "Vectors are about similarity, not exact results. These are different problems with different storage needs." -> delete

**Notes:**
Relational storage is built to find the row that equals something: equality, ranges, B-tree seeks, joins on keys. A Harrier vector has 1,024 dimensions and almost never matches another vector exactly, so the question becomes "find the closest." An ordinary B-tree index doesn't help with that. It needs different storage and a different kind of index, which is why SQL Server 2025 added a VECTOR data type and vector indexes. Section 3 covers both.

### 2.8 (old 27): Trade a sliver of accuracy for a huge speed-up

**Visible text edits:**
- [TextBox 4] "Exact nearest-neighbor compares your query to every vector, which is accurate but won’t scale well. Approximate search (ANN) is clever about what to compare, trading a tiny bit of accuracy for a massive speed-up. Recall is the fraction of the true closest items ANN actually finds. Embeddings are already an approximation of meaning, so 'close enough' really is close enough." -> "Exact nearest-neighbor compares your query to every vector, which is accurate but won't scale well. Approximate search (ANN) compares against a nearby neighborhood instead of everything, giving up a little accuracy for a large speed-up. Recall is the fraction of the true closest items ANN actually finds. Embeddings are already an approximation of meaning, so a small loss is often acceptable. Section 3 shows how to measure it."

**Notes:**
Exact search, kNN, works like a table scan: compare the query with every vector and sort. It's always right, and it gets slower as the table grows. Approximate search, ANN, uses an index to look only in the likely neighborhood. It's much faster, and sometimes it misses a row exact search would have returned. Recall measures that: of the true top 10, how many did the index find? Don't take "a little" on faith. In section 3 we measure recall on the demo data, including the worst single query. Microsoft's rule of thumb, which also comes back in section 3: exact search is fine under about 50,000 vectors.

### 2.9 (old 28): Three knobs we can control

**Visible text edits:**
- [TextBox 93] "Three dials behind every vector store." -> delete

**Notes:**
Three choices sit behind every vector store. Dimensions are set by the embedding model you pick; Harrier gives 1,024. More dimensions can capture more nuance and take more storage, and section 3 does that storage math. The distance metric is how you measure closeness. Every demo today uses cosine. The index type is how vectors get organized for approximate search, and SQL Server uses DiskANN. In SQL Server you name the metric both when you build the index and when you search, so use the same one in both places.

### 2.10 (old 29): You've seen approximate similarity search already!

**Visible text edits:**
- [TextBox 3] "You've seen approximate similarity search already!" -> "You've already seen approximate similarity search"

**Notes:**
Go back to the Projector neighbors view from the Wake County demo. Clicking a point and getting its nearest neighbors is the same request a vector index answers in SQL Server: given this vector, find the closest ones. You've already done it in a browser, with no database. Drop this slide if the section is running long.

**Check:** Whether the Projector's neighbor list is approximate or exact. If it's exact, retitle the slide "You've already seen nearest-neighbor search" and drop "approximate" from the notes.

### 2.11 (old 31): Text, tokens, embeddings, similarity, storage

**Visible text edits:**
- [TextBox 3] "Text → tokens →  embeddings → similarity → storage" -> "Text, tokens, embeddings, similarity, storage"

**Notes:**
Sections 1 and 2 on one slide. Text becomes tokens, an embedding model turns them into a vector, vectors get compared by distance, and the vectors and the search over them live in your database. Every AI-data feature later today is a piece of this chain. RAG is search over stored vectors with a model on the end, and the agents in section 5 build on that. There's no ledger slide here; this section's row joins section 3's. Next: section 3 takes the chain into SQL Server 2025, starting with the VECTOR column.

---

## Section 3: Vectors in SQL Server: your pilot

### 3.0 (old 62): Vectors in SQL Server

**Visible text edits:**
  - [TextBox 1] "04" -> "03"
  - [TextBox 3] "CHAPTER FOUR" -> "CHAPTER THREE"
  - [TextBox 4] "DATABASE ADMINISTRATION IN A GENERATIVE AI WORLD" -> "VECTORS IN SQL SERVER"

**Notes:**
This section runs about 80 minutes, and lunch follows it. Section 2 showed what vectors are. This
section is about storing and searching them in SQL Server 2025, and it ends with a seven-step plan for
a pilot in your own shop. The order: the VECTOR column and exact search, approximate indexes and
recall, what is GA and what is still preview, where else vectors can live, the demo, measuring recall,
search patterns, and running it in production. Then the plan and this section's ledger rows. The demos
call an embedding model running on the laptop. That's for convenience; the same scripts work against
Azure OpenAI or OpenAI with a change to the model registration.


---

### 3.1 (old 63): What actually changes in your day job?

**Visible text edits:**
  - [TextBox 4] "Embeddings, vector search, and in-database AI calls are now first-class features in SQL Server 2025. This makes it YOUR problem to size, secure, back up, and tune." -> "Embeddings, vector search, and in-database AI calls are now built into SQL Server 2025. That makes them your problem to size, secure, back up, and tune."

(Reason: "first-class" overstates it. Vector indexes and VECTOR_SEARCH are still preview in SQL Server 2025; see 3.7.)

**Notes:**
The question for this section: what changes in your day job? Once the database stores embeddings and
calls a model, sizing, security, backup, and tuning for that workload land on the DBA. The scope here
is running these workloads, not every piece of syntax. Expect someone to ask early whether this is
production-ready. Some of it is GA and some is still preview, and 3.7 has the exact split, so defer
the question until then. Handoff: start with the column itself.

---

### 3.2 (old 65): An embedding is just an array of floats in a VECTOR(n) column

**Visible text edits:**
  - [TextBox 4] "Each element is a 4-byte single-precision float by default and we need to fix the number of dimensions per column. The new question becomes, given a query vector, how do I quickly find the closest rows when I have millions of them to search through?" -> "Each element is a 4-byte single-precision float by default, and the number of dimensions is fixed per column. The new question: given a query vector, how do you quickly find the closest rows among millions?"

**Notes:**
An embedding is a fixed-length array of numbers, and SQL Server 2025 stores it in a VECTOR(n) column.
The type is GA. Each element is a 4-byte float by default, and a column can hold 1 to 1,998
dimensions. Half-precision (float16) vectors go up to 3,996 dimensions, but they're preview. The demo
columns are VECTOR(1024) because the Harrier model returns 1,024 numbers for each piece of text. The
dimension count has to match the model, so changing models means re-embedding. Keep it concrete for a
room that thinks in rows and columns: the row has one more column, and it's a big one. Handoff: given
a query vector, how do you find the closest rows?

---

### 3.3 (old 66): Exact kNN computes VECTOR_DISTANCE to every row, sorts, takes top N

**Visible text edits:** none

**Notes:**
Exact k-nearest-neighbors: compute VECTOR_DISTANCE from the query vector to every row, sort, and take
the top N. VECTOR_DISTANCE is GA and supports cosine, dot product, and Euclidean distance. It's a scan
plus one distance calculation per row, so the cost grows with the row count, but the answer is exact
and the plan is predictable. The 50,000 figure at the bottom is Microsoft's published rule of thumb.
It counts candidate vectors, so a WHERE clause that cuts a big table down to a small set makes exact
search the right tool again. Queries A and C in the demo are exact searches. Handoff: past that size,
you trade exactness for speed.

---

### 3.4 (old 67): A vector index returns approximate results

**Visible text edits:**
  - [TextBox 4], third paragraph: "This is usually acceptable because embeddings are already lossy approximations of meaning, so recall ~0.95–0.99 usually changes nothing the user notices." -> "This is usually acceptable: embeddings are already lossy approximations of meaning, so a recall of 0.95 to 0.99 rarely changes anything a user notices."

**Notes:**
Name this shift out loud. Every index this room has tuned returns exact results. A vector index
doesn't: it quickly returns rows that are probably among the nearest. Recall measures how close it
got, as the share of the true top N that the index returned. A recall of 1.0 means the same rows exact
search would return. The 0.95 to 0.99 range is usually fine because embeddings are already an
approximation of meaning. Nobody has to take that range on faith: 3.12 and 3.13 measure recall on the
demo data. Handoff: how these indexes are built.

---

### 3.5 (old 68): Styles of Vector Indexes

**Visible text edits:**
  - [TextBox 45] "Microsoft has gone all-in on DiskANN for its vector search capabilities." -> "DiskANN is the only vector index type in the SQL Server family."

**Notes:**
Three index families, compared on what a DBA cares about: memory, build cost, and recall. IVFFlat
clusters the vectors and searches the nearest few clusters. It builds fast, and its recall depends on
how many clusters you probe. HNSW is a layered graph kept in memory, with excellent recall and costly
builds and updates. DiskANN is a single graph kept on SSD, so you can index far more vectors than fit
in RAM and still get low latency. It balances memory, CPU, and I/O, a trade-off anyone who tunes
storage knows. DiskANN is the one to understand, because it's the only type the SQL Server family
offers. Cosmos DB has it too, and so does Azure Database for PostgreSQL, through the pg_diskann
extension (GA). Handoff: do you need an index at all?

---

### 3.6 (old 70): Index or brute force?

**Visible text edits:** none

**Notes:**
Three questions decide it. Under about 50,000 candidate vectors: exact kNN with VECTOR_DISTANCE, no
index. Large and latency-sensitive: a DiskANN index searched with VECTOR_SEARCH. A selective filter:
it may shrink the set enough that exact search wins again. The exact path is GA; the index path is
preview. SQL Server 2025 gives you few knobs. CREATE VECTOR INDEX takes METRIC and TYPE. It accepts
MAXDOP but ignores it, which is a documented known issue. A VECTOR_SEARCH whose METRIC differs from
the index's falls back to exact kNN, with a warning. So most of the tuning is choosing exact or
approximate and getting the filters right. Handoff: what's GA and what isn't.

---

### 3.7 (old 71): What's in SQL Server 2025

**Visible text edits:**
  - [TextBox 26] "Preview features are available in the product today but you explicitly need to enable them." -> "Preview features ship in the product today, but you have to turn them on (PREVIEW_FEATURES = ON)."

**Notes:**
This is the status slide; people will photograph it. GA in SQL Server 2025: the VECTOR type and its
functions, exact kNN with VECTOR_DISTANCE, and AI_GENERATE_EMBEDDINGS, AI_GENERATE_CHUNKS, and CREATE
EXTERNAL MODEL. Preview, behind PREVIEW_FEATURES: CREATE VECTOR INDEX, VECTOR_SEARCH, and float16
vectors. The embedding functions need two things the type doesn't: an HTTPS model endpoint, and the
server option "external rest endpoint enabled", which the first demo script turns on. Running a local
ONNX model instead of an endpoint is still preview and Windows-only. If someone asks whether they can
run preview features in production, the useful answer for a pilot: everything here works for one, and
exact search is GA if you need to stay off preview. Handoff: the rest of the SQL family is ahead.

---

### 3.8 (old 72): The Microsoft SQL family

**Visible text edits:**
  - [TextBox 40] "Full DML, iterative filtering, and advanced quantization are currently only available in Azure." -> "Full DML, iterative filtering, and advanced quantization are currently only in Azure SQL Database, Fabric SQL Database, and Managed Instance (Always-up-to-date)."

**Notes:**
Same engine family, different versions of the vector index. Azure SQL Database and SQL database in
Fabric have vector indexes and VECTOR_SEARCH GA, with no flag. Managed Instance is GA on the
Always-up-to-date update policy; on the SQL Server 2025 policy it behaves like SQL Server 2025, so
preview. The difference is the index version. SQL Server 2025 ships the earlier one. The latest one
adds full DML on indexed tables, iterative filtering, quantization, an optimizer that chooses between
ANN and kNN, and sys.dm_db_vector_indexes. It also replaces VECTOR_SEARCH's TOP_N parameter, now
deprecated, with SELECT TOP (N) WITH APPROXIMATE. If asked when SQL Server 2025 gets the latest
version: we have no date, so don't guess. Handoff: what the earlier version means for your loads.

---

### 3.9 (old 73): Plan your ETL around the read-only index

**Visible text edits:**
  - [TextBox 4], first sentence: "SQL Server 2025's current vector-index version is read-only after index creation" -> "SQL Server 2025 ships the earlier vector-index version, which is read-only after index creation" (the rest of the box is unchanged)

**Notes:**
This is the most important operational caveat in the section. SQL Server 2025 has the earlier index
version, and it comes with four rules. The table is read-only once the index exists. You need at
least 100 rows before you build it. The table needs a clustered primary key on an int column. And
filters run after the search, not during it (3.15 covers that). So every load becomes: drop the index,
load and embed, rebuild. Azure SQL Database and Fabric have an option, ALLOW_STALE_VECTOR_INDEX, that
keeps old-version indexed tables writable; SQL Server 2025 doesn't have it. The demo database is in
this state right now: both vector indexes exist, so FoodInspectionViolation is read-only. Handoff:
before the demo, where else vectors can live.

---

### 3.10 (old 76, with one line each from 74 and 75): In-database vs dedicated store: decide

**Visible text edits:**
  - [new box, under the five criteria, before TextBox 32] add: "Already on Cosmos DB? It has DiskANN too, set through a JSON index policy and billed in RUs."
  - [new box, under the five criteria, before TextBox 32] add: "Already on PostgreSQL? pgvector offers HNSW and IVFFlat; Azure Database for PostgreSQL adds DiskANN (pg_diskann)."

**Notes:**
The default recommendation, stated plainly: if the vectors describe rows you already keep in SQL
Server, keep them there. You skip a sync pipeline, the embeddings stay consistent with their source
rows, and there's one engine to back up, secure, and patch. A dedicated store earns its place at the
far end of scale and latency, such as billions of vectors at low latency. The two new lines are for
people whose data already lives elsewhere. Cosmos DB also offers quantizedFlat and flat indexes, and
can shard DiskANN by partition key, one graph per key value, which helps with multi-tenant isolation.
pgvector is open source. If someone asks about Pinecone, Weaviate, Qdrant, Milvus, or Elasticsearch:
they can be better at pure vector work, and each is another system to back up, test, and plan RPO and
RTO for. Don't rank them. Handoff: the demo.

---

### 3.11 (old 77): Demo: Working with vector indexes in SQL Server 2025

**Visible text edits:** none (TextBox 55 must carry the corrected subtitle "Exact kNN, a DiskANN index, and approximate search over Wake County violation comments." from `deck-changes-2026-11.md`, not the copy of slide 66's line)

**Notes:**
Setup is in src/demo/block4/README.md: Harrier on Ollama behind the TLS proxy, because CREATE EXTERNAL
MODEL only accepts HTTPS endpoints. Run these in order:

1. src/demo/block4/10_create_external_model.sql: enable external REST endpoints, register Harrier as
   an external model, smoke test. The result is an array of 1,024 numbers.
2. src/demo/block4/20_generate_embeddings.sql: show it, don't run it. Embedding was done ahead of
   time: 2,000 of about 311,000 violation comments. The vector indexes already exist, so its UPDATEs
   would fail. Point out the batch loop and the blank-text skip, and tell why the skip is there: an
   empty string fails the statement with Msg 31744, and that takes the whole batch of 2,000 with it.
3. src/demo/block4/30_create_vector_index.sql: CREATE VECTOR INDEX with METRIC and TYPE, then the
   query on sys.vector_indexes.
4. src/demo/block4/40_vector_search.sql: Query A is exact kNN over inspection narratives. Query B is
   VECTOR_SEARCH over violation comments for "rodent or pest activity in the kitchen": roach, fly, and
   mouse comments come back that share none of those words with the question. Query C filters to
   Raleigh, then runs exact kNN. B' (commented out) shows the SELECT TOP (N) WITH APPROXIMATE form
   used on Azure.

Ledger rows from this demo: the pest result (Worked); the blank-text failure and the read-only table
(Broke). To put both Broke rows on screen instead of telling them, run
SELECT AI_GENERATE_EMBEDDINGS(N'' USE MODEL HarrierEmbeddings); (Msg 31744, "The JSON path for
embeddings could not be found in the response.") and try one UPDATE on FoodInspectionViolation
(Msg 42231, "Data modification statement failed because table 'FoodInspectionViolation' has a vector
index on it."). Both were tested on the demo container on 2026-11-01. A string of spaces does NOT fail;
it gets a vector, so use the empty string.

**Check:** 30_create_vector_index.sql drops and rebuilds both indexes; decide in rehearsal whether to run it live or only show it.

---

### 3.12 (new): Is the index giving the right answers?

**Visible text:**
- A vector index is approximate. It can return different rows than a full scan would.
- Measure it: run the same queries both ways and compare the top 10.
- Recall@10 = how many of the exact top 10 the index also found, divided by 10.
- Measure on your real data at your real size. Recall changes as the table grows.

**Notes:**
This is the check you run before you tell anyone the pilot works. A vector index is approximate, so
measure it against exact search. On SQL Server 2025 that's simple to set up: VECTOR_DISTANCE is exact
and VECTOR_SEARCH uses the index, so you run the same query both ways and compare the top 10. Measure
at your real size, because a number from 2,000 rows says little about 2 million. Watch out for ties.
Violation comments repeat word for word, identical text gets an identical vector, and when several
comments tie for 10th place, the two lists can pick different rows from the tie. Counting row IDs
alone would call that a miss. The script reports both a naive measure (INTERSECT of row IDs) and a
tie-aware one. Handoff: the demo.

---

### 3.13 (new): Demo: measuring recall

**Visible text:**
Two columns.
- Left, "25 sample rows": recall@10 0.97; worst single query 0.70.
- Right, "One question" ("rodent or pest activity in the kitchen"): 8 of the top 10 in both lists.

**Notes:**
File: src/demo/block4/50_recall_check.sql. Run it after 30_create_vector_index.sql; it takes about
5 seconds.

Part A needs no endpoint. It picks 25 evenly spaced embedded rows, uses each row's own vector as the
query, and compares the index's top 10 with the exact top 10, leaving the query row out. It returns
id_recall, tie_recall, and the worst single query, then lists the queries where the two lists
differed.

Part B embeds the pest question from 40_vector_search.sql and shows both lists side by side. A row
with in_both = 0 was found by only one method.

The slide numbers were measured on 2026-11-01 on the 2,000-row demo set. Rerun before the session and
update the slide if the embedded set has changed.

The question to leave with the room: is 0.97 good enough? That depends on what the search is for, and
it's a call for someone who knows the data. It goes on the ledger as Broke because 8 of 10 isn't 10
of 10. Handoff: search patterns beyond a single query.

On the 2026-11-01 run, id_recall and tie_recall were both 0.97, so either is right to quote; the 0.70 worst query is from the tie-aware column.

---

### 3.14 (old 78): Pure vector vs hybrid search

**Visible text edits:**
  - [TextBox 27] "Best of both for real relevance" -> "Often more relevant than either one alone"

**Notes:**
Pure vector search ranks by meaning, which is how query B found the pest comments. It fumbles exact
tokens: product codes, people's names, rare jargon. Keyword search with full-text is precise on
exactly those. Hybrid runs both in one query and merges the results. Full-text search is GA in SQL
Server 2025; the vector side is GA with VECTOR_DISTANCE and preview with VECTOR_SEARCH. A quick test
for whether your pilot needs hybrid: write down a few real questions that contain a code or a name,
and see whether vector search alone finds the right rows. Handoff: filtering has its own trap.

---

### 3.15 (old 79): Filtered search and the post-filter trap

**Visible text edits:**
  - [TextBox 27] "Currently only available in Azure/Fabric SQL DB" -> "Currently only in Azure SQL DB, Fabric, and MI (Always-up-to-date)"
  - [TextBox 32] "SQL Server 2025 currently does not support iterative filtering. One workaround: apply non-vector filters and load data into a temp table prior to vector search." -> "SQL Server 2025 doesn't support iterative filtering. Workaround: apply the non-vector filters first, then run exact kNN over the rows that remain."

**Notes:**
With post-filtering, the index finds its top N first and the WHERE clause runs afterward. If most of
those N fail the filter, you get back far fewer rows than you asked for, and the ones you lost may
have been the best matches inside the filter. Iterative filtering applies the filter during the graph
search and returns a full result. It's part of the latest index version: Azure SQL Database, Fabric,
and Managed Instance on Always-up-to-date. SQL Server 2025 only post-filters. The workaround is query
C in 40_vector_search.sql: filter on metadata first, then run exact kNN with VECTOR_DISTANCE over
what's left. When the filter is selective, that's the faster plan anyway. Handoff: combining two
ranked lists.

---

### 3.16 (old 80): You can't just add a distance score and a BM25 score: hybrid ranking

**Visible text edits:** none

**Notes:**
A cosine distance and a full-text rank are on different scales, so you can't add them. Reciprocal Rank
Fusion ignores the raw scores and uses each row's position in each list, with a weight per list if you
want to favor semantic or keyword results. In SQL, that's VECTOR_DISTANCE or VECTOR_SEARCH for one
list and FREETEXTTABLE for the other, combined by rank. RRF stays in the database and needs no extra
model. If someone asks about re-ranking with a model such as Cohere Rerank: a second model scores the
top few results, which is more precise but adds an external call, with its latency and cost. Use it
on the top K, not the whole result set. This is the first slide to drop if the section runs long.
Handoff: getting embeddings into the table.

---

### 3.17 (old 82): Batch vs real-time embedding generation

**Visible text edits:** none

**Notes:**
Two ways to fill the embedding column. Batch: run AI_GENERATE_EMBEDDINGS over the table on a schedule,
which is what 20_generate_embeddings.sql does, 2,000 rows at a time. Real-time: embed on insert or
update, so new rows are searchable at once, at the cost of a model call for every row. On SQL Server
2025 there's a catch: a vector-indexed table is read-only, so real-time embedding only works on a
table without a vector index. Either way, you own staleness. When the text changes, its embedding is
wrong until you regenerate it, and the refresh can come from triggers, CDC, or a scheduled job. The
functions are GA and work with Azure OpenAI, OpenAI, and Ollama endpoints. A local ONNX model is still
preview and Windows-only. Handoff: how big this gets.

---

### 3.18 (old 83): Capacity planning: do the vector math

**Visible text edits:** none

**Notes:**
Do this math before the pilot. A 1,024-dimension float32 vector is 4,096 bytes of payload plus an
8-byte header, 4,104 bytes. A data page holds 8,060 bytes, so that's about one vector per page. At
1,536 dimensions (OpenAI's ada-002), a row is about 6 KB, and 10 million rows come to about 60 GB
before any index overhead. Float16 halves the storage and allows up to 3,996 dimensions, at some
recall cost, and it's preview. Embeddings often outweigh the rows they describe, so size data, log,
and backups for them, and pick the smallest dimension count that does the job. Step 7 of the pilot
plan uses this slide. Handoff: when to build the index.

---

### 3.19 (old 84): Build after bulk load: the index gate closes behind you

**Visible text edits:**
  - [TextBox 4], second paragraph: "Warning: SQL Server tables are read-only after you apply a vector index!" -> "Warning: on SQL Server 2025, a table is read-only once it has a vector index."

**Notes:**
The order for any load: bulk load the rows, generate the embeddings, build the index last. Once the
index exists the table is read-only, so adding data later means dropping the index, loading and
embedding, then rebuilding, with at least 100 rows in place. Plan that window into the ETL schedule.
DiskANN keeps its graph on SSD, so memory pressure is much lower than with an in-memory HNSW index over
the same data. Build time grows with row count and parallelism. SQL Server 2025 ignores MAXDOP on
CREATE VECTOR INDEX (a known issue), so set MAXDOP at the server or database level before a big
build. This is the second slide to drop if the section runs long; 3.9 already makes the read-only
point. Handoff: running it day to day.

---

### 3.20 (merged 85+86): Running it: monitoring and backup

**Visible text (full merged body, two columns):**

Title: Running it: monitoring and backup

MONITOR
- sys.vector_indexes: index type, distance metric, build parameters.
- Extended Events ai_generate_embeddings_summary and external_rest_endpoint_summary: status codes, errors, model name.
- The model endpoint is a new dependency. Watch its latency, throttling, and failures.
- Recall can drift as the data changes. Rerun the recall check on a sample.

BACK UP AND RECOVER
- Vectors back up with the table. The model doesn't.
- Pin the embedding model and its version. Stored vectors are useless if you can't embed new text with the same model.
- Keep the CREATE EXTERNAL MODEL and credential scripts in your runbook.
- TRUNCATE is blocked on a vector-indexed table: drop the index, truncate, reload, rebuild.

Bottom line: Query Store, wait stats, and your existing tools still apply: vector queries show up as ordinary query plans.

(Dropped from old 86: the footer "Your recovery runbook needs three things backups won't hand you..." It contradicted 86's own item 02, which said backups include the database-scoped credentials.)

**Notes:**
Most of this is familiar: vector queries show up as ordinary plans, so Query Store and wait stats
still work. Three things are new. sys.vector_indexes shows what you built. The two Extended Events,
which are GA, track calls to the model endpoint. And that endpoint is a dependency: if it slows down,
throttles, or fails, so does every embedding call. The two-space comment from the demo was one of
those failures. On the latest index version only, sys.dm_db_vector_indexes also shows background
maintenance. For backup: vectors are columns, so they back up with the table. The model itself lives
at an endpoint you don't back up. If the model or its version changes, new query vectors stop
matching the stored ones, so pin both. For DR: vector indexes aren't replicated to subscribers, can't
be partitioned, and can't be deployed with a DacPac; BACPAC works from DacFx 170.5.96.

**Check:** Old 86 contradicted itself on whether a backup carries the external model's credentials. The merged text avoids the claim; confirm the restore behavior before answering that question on stage.

---

### 3.21 (old 90, rebuilt): Your pilot, step by step

**Visible text (replaces all of old 90's body, including the "Block 4 takeaways" title):**

Title: Your pilot, step by step

1. Pick one table with text people already search, and the questions they ask of it.
2. Pick an embedding model and an HTTPS endpoint.
3. Embed in batches. Skip blank text. Log what fails.
4. Search with exact kNN first. Under about 50,000 rows, you may never need an index.
5. If you index: build it last. On SQL Server 2025 the table goes read-only, and it needs an int clustered primary key.
6. Measure recall against exact search on a sample.
7. Time the embedding run, then do the math for the full table.

**Notes:**
Each step points back to something from this section. Step 1 is the data-gravity argument from 3.10.
Step 2 is 3.7 and the first demo script; the endpoint has to be HTTPS. Step 3 is 3.17 and
20_generate_embeddings.sql, where one empty string would fail a whole batch. Step 4 is 3.3
and 3.6. Step 5 is 3.9 and 3.19. Step 6 is 3.12 and 50_recall_check.sql. Step 7 is the capacity math
from 3.18, plus a measured rate. The demo's own runs, on a laptop with a Radeon 780M GPU: about 70,000
inspection narratives took about 3 hours, a little under 400 rows a minute, while about 311,000 short
violation descriptions took 1 hour 40 minutes. Text length matters as much as row count, so time your
own model on your own text. Handoff: the ledger.

**Check:** The timings come from the comments in 20_generate_embeddings.sql; confirm they were Harrier runs on the laptop you'll present from.

---

### 3.22 (new): Ledger, sections 2 and 3

**Visible text:**
Two columns, "Worked" and "Broke". Section 1 rows carried over; sections 2 and 3 rows new and highlighted.

Carried over (section 1):
- Worked: at temperature 0, the same prompt gave the same answer.
- Broke: at high temperature, the same prompt gave different answers each run.

New (sections 2 and 3):
- Worked: violation comments about the same problem clustered together with no keywords in common.
- Worked: "rodent or pest activity in the kitchen" found roach, fly, and mouse comments that share none of those words with the question.
- Broke: an empty string doesn't come back as NULL. It fails the statement (Msg 31744), and in a batch UPDATE that one row fails the whole batch.
- Broke: once indexed, the table went read-only. Adding rows means drop the index, embed, rebuild.
- Broke: for the pest question, the index's top 10 matched the exact top 10 on 8 of 10 rows. Across 25 sample rows, recall was 0.97; the worst single query was 0.70.

**Notes:**
The two section 1 rows carry over; the highlighted rows are new. The first came from the Embedding
Projector in section 2, the rest from this section's demos. Read the new rows briefly, and for each
Broke row, point out who caught it: a person who knew to look. Everything here happened on screen
today; none of it is an industry statistic. Spend a moment on the recall row. 8 of 10 may be fine for
finding similar comments and not fine for every use, and deciding which is a job for someone who knows
the data. Then lunch. After lunch, section 4 puts these vectors to work: find the passages that answer
a question, and hand only those to the model.

**Check:** The empty-string row is on-screen only if the one-line call in the 3.11 notes is run live; if it isn't, drop the row.
**Check:** Recall numbers are from 2026-11-01 on the 2,000-row set; rerun 50_recall_check.sql before Friday and update this slide and 3.13 together.

---

## Section 4: RAG

### 4.0 (new): RAG

**Visible text:**
- 04
- CHAPTER FOUR
- RAG
- Subtitle: You find the relevant context and hand it to the model.

**Notes:**
Welcome back from lunch. The morning answered one question: how does a model get your
context? Section 3's answer was to turn your data into vectors a model can search. This
section takes the next step: find the passages that answer a question and hand only those to
the model. That's RAG. By the end you'll have seen a basic RAG pipeline built entirely in
T-SQL, and a way to test whether its retrieval finds the right documents before anyone trusts
its answers. Section 5 takes one more step, where the model looks things up itself.

### 4.1 (old 101): Retrieval Augmented Generation (RAG)

**Visible text edits:**
- [TextBox 67] "Block 4 gave you vectors. 5.2 gave you tools that fetch context. RAG is the third pillar: point the model at your runbooks, incident logs, and schema docs, then let it retrieve the right passage before it answers. Same recipe, aimed at the knowledge your team already wrote down." -> "Section 3 turned your data into vectors. RAG puts them to work: find the passages that answer a question, and hand only those to the model."

**Notes:**
The name describes the steps. Retrieve: search your documents for the passages closest to
the question. Augment: put those passages into the prompt. Generate: the model writes the
answer from them. The documents that pay off first are the ones your team already wrote:
runbooks, incident logs, schema docs. Everything in the retrieve step is what you did with
violation comments in section 3, aimed at documents instead. Next we put it in DBA terms.

### 4.2 (old 102): What RAG is, in DBA terms

**Visible text edits:**
- [TextBox 73] "The model knows the world, not your shop. Ask about your failover runbook and it guesses confidently." -> "The model has never seen your shop's documents. Ask about your failover runbook and it guesses confidently."
- [TextBox 79] "Prepend those passages to the prompt as grounding. The model answers from your text, not its training." -> "Prepend those passages to the prompt and tell the model to answer from them."
- [TextBox 83] "RAG is a WHERE clause for meaning, wired into the prompt." -> delete

**Notes:**
If it helps the room, think of RAG as a WHERE clause on meaning whose results get pasted into
the prompt. The model hasn't learned anything new; it's reading what you handed it. Two
consequences worth saying out loud. First, the model is told to answer from the passages,
and it usually does, but that's an instruction the model can still ignore. Second, there's no training
step: when a runbook changes, you re-embed that document's chunks and the next answer
reflects it. Likely question: why not fine-tune instead? Fine-tuning bakes the content into
the model, so every document change means another training run. RAG is a lookup you can
update the same day.

### 4.3 (old 103): Turn tribal knowledge into context

**Visible text edits:**
- [TextBox 102] "The stuff in wikis, Slack, and people's heads becomes searchable grounding." -> delete

**Notes:**
These four are where the useful text in a data team usually lives. Ask the room where their
failover runbook is and when someone last opened it. The demo corpus is six documents of this
kind: five runbooks (availability group failover, backup and restore, blocking and deadlocks,
index maintenance, tempdb contention) and one post-mortem of a failed nightly ETL run. Start
with documents people already go looking for and that are mostly current. An out-of-date
runbook gives out-of-date answers, and that's on the list of failures at the end of this
section. Drop this slide if the section runs long.

### 4.4 (old 104): Chunking: finding context in large files

**Visible text edits:**
- [TextBox 118] "Good chunks in, good answers out. This is the lever, not the model." -> delete

**Notes:**
Embeddings match passages, so a whole runbook as one vector matches everything a little and
nothing well. The demo uses AI_GENERATE_CHUNKS in SQL Server 2025 with the simplest option:
fixed 800-character chunks with 15 percent overlap, roughly 150 to 200 tokens each. Be honest
about that: fixed-size chunks can cut mid-sentence or mid-procedure, which is what the overlap
is there to soften, and splitting on headings would do better. Each chunk keeps its document
name and order, which is the metadata the answer cites. When answers are bad, look at
chunking and retrieval before you blame the model; slide 4.7 shows how to measure that.

### 4.5 (old 105): A minimal RAG pipeline

**Visible text edits:**
- [TextBox 140] "Five steps. You already know steps 3 and 4 from earlier." -> "You ran steps 3 and 4 in section 3."

**Notes:**
Map each step to a demo script. Load is `01_load_docs.sql`, which inserts the runbook text
into a table. Chunk and embed happen together in `02_index.sql`, one INSERT ... SELECT. Store
is a VECTOR(1536) column on the chunk table, with no vector index: about 18 chunks is far
below the roughly 50,000 vectors where an index starts to pay off, so exact search is the
right tool. Retrieve and stuff is `03_rag.sql`: embed the question, take the four closest
chunks by cosine distance, join them into one context string, and send that with the
question to the chat model. One rule people miss: embed the question with the same model you
used for the chunks.

### 4.6 (old 106): Demo: RAG over sample DB docs

**Visible text edits:**
- [TextBox 155] "Cites the actual passage" -> "Cites the source document"
- [TextBox 161] "RAG lets your LLM-generated responses retain credibility: they don’t make up answers." -> delete

**Notes:**
Files: `src/demo/block5/tsql/00_setup.sql` through `03_rag.sql`. Setup (Foundry endpoint,
deployments, key placeholders) is in `src/demo/block5/README.md`. Run 00 to 02 before the
session and walk through them; run 03 live.
1. `02_index.sql`: one statement chunks and embeds every document. The last query shows the
   chunk, embedded, and document counts.
2. `03_rag.sql` with the default question about the nightly load and the full log. It's worded
   the way a user would ask, and the answer should cite failed-nightly-etl-postmortem.md.
   Show the `retrieved_context` column so the room sees what the model was given.
3. Change `@question` to one from the README list, such as the frozen app, and rerun.
4. Uncomment the out-of-scope question in the script and rerun. The model should say it
   doesn't know. Then show `retrieved_context`: four chunks came back anyway. The "I don't
   know" came from the system prompt's instruction, not from retrieval. That sets up 4.7.
A Python version of the same pipeline is in `src/demo/block5/python/rag.py` if anyone asks.

**Check:** The scripts have no run without RAG. Decide how to show the left column (ask a chat model the same question cold, or talk through it).

### 4.7 (new): Test retrieval before you trust the answers

**Visible text:**
- An answer is only as good as the chunks retrieval found.
- Write down 10 to 20 real questions, and for each one, the document that should answer it.
- Run them after every change: chunk size, overlap, model, top-k, or the documents.
- Track two numbers: right document in the top k, and right document at rank 1.

**Notes:**
This is the RAG version of the recall check from section 3. There, we compared the index with
exact search. Here, we compare retrieval with an answer key you wrote yourself. Word the
questions the way a user would ask them, not the way the runbook is written, because that's
the case that matters. Include at least one question no document answers, and watch how close
its best match is. The test never calls the chat model, so it's cheap to run as often as you
like. Next, the script that does this.

### 4.8 (new): Demo: testing retrieval

**Visible text:**
A results table from the script's output, columns: question, expected document, rank, in top 4.

**Notes:**
File: `src/demo/block5/tsql/04_eval.sql`. Run it after `02_index.sql`. It embeds seven test
questions, six with a known source document and one about Kafka retention that no document
covers, and never calls the chat model.
1. First result set: one row per question with the rank of the right document, whether it
   made the top 4 that `03_rag.sql` sends to the model, and what actually came back first
   and how close.
2. Second result set: the score to track from run to run, found in the top k and found at
   rank 1.
3. Point at the Kafka row's best distance next to the in-scope questions'.
The 2026-11-01 test run used the local Harrier model, not Foundry: 6 of 6 at rank 1, and the
out-of-scope question's best distance was 0.595 against 0.344 to 0.540 for the real
questions. That gap is too small to set a cutoff on. **[fill]** with the Foundry run. If the
Foundry run arrives too late, show the table without numbers and run the script live.

**Check:** Kevin runs `04_eval.sql` against Foundry before Friday and fills in the numbers here and on 4.10.

### 4.9 (new): Where RAG goes wrong

**Visible text:**
- It retrieves the wrong chunk, so the answer is confidently about something else.
- The document is out of date, so the answer is out of date.
- Nothing answers the question, but retrieval still returns its closest matches.
- A chunk splits a list of steps, so the answer gets half the procedure.
- Retrieval doesn't know who's asking. If a document is in the index, anyone can get it back.

**Notes:**
Tie each one to what the room saw. The test questions on 4.8 catch the first one. The second
needs a process: when a runbook changes, reload and re-embed it. The third happened on screen:
the out-of-scope question still got four chunks. The fourth is the risk of the fixed-size
chunks in our demo. The last one is the one DBAs should own. Row-level security or per-user
filtering on the chunk table is the fix; the model won't do it for you.

### 4.10 (new): Ledger, section 4 rows

**Visible text:**
The ledger, with the rows from sections 1 to 3 carried over (full list on 6.1) and these new
rows highlighted:
- Worked: every one of 6 test questions found its runbook at rank 1. **[fill]** with the Foundry run.
- Worked: asked about something no runbook covers, the model said it didn't know instead of making something up. **[fill]** from the live run of the out-of-scope question in `03_rag.sql`.
- Broke: for a question no runbook covers, retrieval still handed the model four chunks. Retrieval always returns its top k, whether or not any of them answer the question.
- Broke: the out-of-scope question's best match was nearly as close as a real answer's (0.595 vs 0.540), so distance alone can't tell "no answer" from "weak answer". **[fill]** with Foundry's numbers, or drop this row if Foundry separates them clearly.

**Notes:**
Read the new rows. The two that matter go together: the model said "I don't know" because the
system prompt told it to, while retrieval handed it four chunks regardless. Retrieval has no
notion of "nothing here". The first-row numbers come from a run with the local Harrier model
standing in for Foundry on 2026-11-01; replace them with the Foundry run. If a row didn't
happen on screen today, drop it. So far we've found the context and handed it to the model.
In section 5 the model looks it up itself, and then acts on it.

**Check:** Confirm or drop each **[fill]** row after the Foundry run and rehearsal.

---

---

## Section 5: Agents: the good and the bad (Jonathan; Kevin presents 5.19)

Two section-wide items for the presenters:
- Order inside "Letting it act": the tuning slide (5.17), the perf-triage demo running as `sa`
  (5.18), then SSMS Agent mode with its own identity and rules (5.19, 5.19a) as the answer.
  Kevin presents 5.19; presenting 5.17 to 5.19 as one block is the natural split.
- The mid-section break goes after 5.12 (end of "Pairing with it"), so all the MCP and agent demos come after it.

---

### 5.0 (old 36): Agents: the good and the bad

**Visible text edits:**
  - [TextBox 1] "02" -> "05"
  - [TextBox 3] "CHAPTER TWO" -> "CHAPTER FIVE"
  - [TextBox 4] "TOOLING + SECURITY" -> "AGENTS: THE GOOD AND THE BAD"

**Notes:**
This section takes the thread one step further. In RAG, we found the context and handed it to
the model. Here the model looks things up itself, and then acts on what it finds. We go in five
steps, each giving the model more reach: what to settle before you hand it anything, how to
brief it, how to pair with it, letting it fetch its own context, and letting it run queries.
Then we cover how to guard it. Every demo in this section adds rows to the ledger, and this
section adds more "Broke" rows than any other. Keep both columns in mind; the last section uses
them.


---

### 5.1 (old 37): The gap between what we do and what we know

**Visible text edits:**
  - [TextBox 4] "Who's pasted a production schema into ChatGPT? Now keep your hand up if you know exactly what that vendor is allowed to do with it. That gap is the whole talk." -> "Who's pasted a production schema into ChatGPT? Now keep your hand up if you know exactly what that vendor is allowed to do with it."

**Notes:**
Ask it as a show of hands, then the second half. Most hands go up for the first question and
most come down for the second. Don't shame anyone; nearly everyone in the room has done it,
including us.
The point: before we give a model any more reach, we need to know where our data goes when we
type. The rest of this part covers where the prompt travels, what's at risk, which tier of tool
fits which data, and what a usable AI policy says. Those decisions come first because
everything later in this section hands the model more of your data and more access.

---

### 5.2 (old 38): Where your prompt actually goes

**Visible text edits:** none

**Notes:**
Walk the four boxes left to right. The prompt, with whatever schema, plan, or sample rows you
pasted, leaves your machine when you hit enter. On the vendor's side it may be logged,
retained, and read by people reviewing quality. On consumer tiers it can end up training the
next model.
The fourth box is the way out: a model that runs on your own hardware. We aren't covering local
models today beyond this mention, but the temperature demo this morning ran llama3.2 on the
laptop through Ollama, so you've already seen one.
Likely question: "Does the enterprise tier train on my data?" The next slides cover the tiers.

---

### 5.3 (old 40): What's actually at risk

**Visible text edits:** none

**Notes:**
Five kinds of exposure. PII is the one everyone thinks of. The other four are easy to miss:
your schema is intellectual property; sample code often carries connection strings; the
procedures you paste for a refactor describe how the business runs; and even anonymized rows
reveal distributions, cardinalities, and naming conventions.
Inference is the one to slow down on. Removing names doesn't remove what the data says about
your business.
If the section is running long, skip this slide; 5.4 and 5.5 carry the decisions.

---

### 5.4 (old 41): Capability vs. control: match the tier to the task

**Visible text edits:**
  - [TextBox 123] "Classify the data first — the tier, and the tool, fall out of that." -> delete

**Notes:**
Three tiers and a rule. Consumer cloud has the best models and the worst data terms: assume
prompts are kept and used for training unless you've opted out. Enterprise cloud (Foundry,
Azure OpenAI, Copilot, Claude Team or Enterprise) runs the same models under a contract: no
training on your data, data residency, and audit. Local or self-hosted keeps data on your
network, at the cost of weaker models and running it yourself.
The rule is to pick per task, by how sensitive the data is. One tier for everything means
either leaking data or giving up capability you didn't need to.
"Claude for Work" was an older umbrella name; Anthropic sells this tier as the Team and
Enterprise plans.
Next: classifying the data is what decides the tier.

---

### 5.5 (merged 42+43): Your AI use policy

**Visible text** (full merged body; layout is Jonathan's call, for example a list with a small
three-row table under the second item):

Title: Your AI use policy

- Approved tools and tiers: which assistants and licenses are allowed, and which are banned.
- Data classification decides the tier. Some data may never be pasted, whatever the tier.

  | Regime | Data in scope | What you need before you prompt |
  |---|---|---|
  | HIPAA | US health data | A BAA. Consumer tiers don't offer one. |
  | PCI-DSS | Card payments | Keep card data out of the prompt entirely. |
  | GDPR | EU personal data | A DPA, data residency, no training, and right to erasure. |

- A person reviews AI output before it reaches production.
- No production write access: read-only by default, with guardrails on anything that runs.
- Sign-off and logging: who approved the tool, who used it for what, and who owns the result.
- A sanctioned path. A policy that only says "no" sends people to tools you can't see.

**Notes:**
This is the checklist to take back to work. Start with the data, not the tool: classify it, and
the classification tells you which tier is allowed. The three regimes on the slide are
examples. HIPAA needs a business associate agreement, which consumer tiers don't offer. Card data
should never be in a prompt. GDPR brings residency and erasure.
Two items on this list come back later in this section. "Read-only by default" is how SSMS
Agent mode ships (5.19). "No production write access" is exactly what the perf-triage demo
(5.18) doesn't follow, on purpose.
The last item matters most in practice. If the only approved answer is "no", people use their
personal accounts and you lose sight of it.
Next: once you know what you're allowed to send, how to brief the model well.

---

### 5.6 (old 53): R-C-T-C-O: the anatomy of an effective prompt

**Visible text edits:**
  - [TextBox 32] "Role and Task are easy. Context, Constraints, and Output differentiate amateur- versus professional-level outcomes." -> delete

**Notes:**
Remember the overconfident junior from the first section. You already write specs for juniors;
a prompt is a spec. Five parts: the role sets vocabulary and standards; context is schema,
version, volumes, conventions, and what you've tried; the task is one verb and one deliverable;
constraints are your standards written down ("set-based, no cursors, runs on SQL Server 2019");
output format saves a round trip.
Everyone writes role and task without thinking about it. Context, constraints, and output format
are where the results improve, and they're the parts people skip. The prompt makeover in a few
slides adds them one at a time so you can see what each one fixes.

---

### 5.7 (old 56): The model can't see your database, so show it the relevant slice

**Visible text edits:** none

**Notes:**
The model has never seen your database. Without your schema it invents table and column names
that look right and don't exist. You'll see that in the first step of the makeover.
What to paste: the CREATE TABLE statements with keys and indexes, a few sample rows, the
relationships, and rough row counts. For a big schema, include the tables that matter and
summarize the rest.
This sits right after the data-handling slides for a reason: paste the slice your policy allows,
into a tier that's approved for it. Later in this section MCP removes the pasting step, and the
model reads the schema itself.

---

### 5.8 (old 55): Reason first, then iterate

**Visible text edits:**
  - [TextBox 15] "First answer is a draft. Read output → spot the wrong assumption → add the missing context → re-ask. Exactly how you'd mentor a junior." -> "The first answer is a draft. Read the output, spot the wrong assumption, add the missing context, and ask again. Exactly how you'd mentor a junior."

**Notes:**
Two habits. First, before it writes any SQL, have it restate the requirement, list the tables
and their grain, and name the join keys. A wrong assumption is cheap to fix in that list and
expensive to find once it's in a query.
Second, treat the first answer as a draft. Read the output, find the wrong assumption, add the
context that was missing, and ask again. That's how you'd mentor a junior, and it's the loop
the next demo runs four times.
If the section is running long, skip this slide and make both points during the demo.

---

### 5.9 (old 60): Demo: the prompt makeover

**Visible text edits:**
  - [TextBox 12] "The 'spot the hallucination' hook" -> "The room spots the invented names"
  - [TextBox 34] "We use the same model throughout. The prompt is entirely responsible improvement in results." -> "Same model throughout. Only the prompt changed."

**Notes:**
Files: `src/demo/block3/prompt-makeover-offline.md` (pre-captured outputs, the default),
`src/demo/block3/claude-code-online.md` (live in Claude Code), and `src/demo/block3/schema.sql`
(the schema handed over at v2). Setup is in `src/demo/block3/README.md`. Use a capable model,
not the laptop's llama3.2:1b.
The task never changes: restaurants with the most critical violations in the last 12 months,
with the count and the most recent score, worst first.
- v1, no context: about 2 minutes. Show the query and let the room find what's wrong. The tables
  don't exist and LIMIT isn't T-SQL.
- v2, role and schema: right tables, but it guesses `Severity = 'Critical'`. 0 rows. The values
  are Core, Priority, and Priority Foundation.
- v3, the Severity values and a date window: a naive join to every inspection turns BASS LAKE
  DRAFT HOUSE's 5 critical violations into 165.
- v4, correctness constraints and house style: a derived-table count and OUTER APPLY TOP (1)
  for the score. Correct.
Ledger: v2 and v3 go in Broke, v4 in Worked. Keep `'Critical'` in mind; it comes back in the
SSMS demo.

---

### 5.10 (old 92): Pair programming: the loop

**Visible text edits:**
  - [TextBox 1] "Pair programming: the real loop" -> "Pair programming: the loop"
  - [TextBox 25] "Add the missing context, re-ask, repeat. Not dictation, not autopilot." -> "Add the missing context, re-ask, repeat."
  - [TextBox 26] "Your job moves from typing to specifying and reviewing. That's a promotion — but only if you actually review." -> delete

**Notes:**
The makeover was this loop with one prompt. Day to day it looks like pair programming: you
specify, using R-C-T-C-O; it drafts, fast and often most of the way there; you review every line
the way you'd review a pull request; you correct by adding what was missing and asking again.
Your work shifts from typing to specifying and reviewing. That only pays off if the review
happens. A draft that's 80% right and merged unread is a bug you shipped faster.
Next: what the remaining 20% usually looks like.

---

### 5.11 (old 94): When AI gets it wrong: the five failure modes

**Visible text edits:**
  - [TextBox 13] "Wrong grain on a join → duplicate rows; NOT IN with NULLs." -> "A join at the wrong grain duplicates rows; NOT IN with NULLs."
  - [TextBox 32] "The people who get burned trust it too much, too early. Trust is earned per task — like a new hire." -> delete

**Notes:**
Five ways it goes wrong, and the room has already seen two. Hallucinated objects was v1 of the
makeover. Plausible-but-wrong logic was v3: the join at the wrong grain that turned 5 into 165.
Version-mismatched syntax is the one the Learn MCP demo addresses shortly. Confidently wrong
performance advice shows up in the perf-triage demo, where it suggests an index you should
check before you build.
The fifth is the hardest habit to break: it always produces something. The RAG demo's prompt
told the model to say it didn't know; left alone, it rarely does. Read the plan and check row
counts at every grain.
Trust it per task, the way you'd trust a new hire: more on the work it has got right before,
less on anything new.

---

### 5.12 (old 95): Demo: requirements to stored procedure

**Visible text edits:**
  - [TextBox 1] "Demo: requirements → stored procedure" -> "Demo: requirements to stored procedure"
  - [TextBox 14] "A real grain bug → duplicate rows" -> "A grain bug that duplicates rows"
  - [TextBox 30] "The failure-mode point lands 10x harder shown than told." -> delete

**Notes:**
Two passes at the same request. First, the under-specified prompt: "Write a proc to dedupe
customers." It produces a mediocre draft with guessed column names and a grain bug that returns
duplicate rows. Let the room look for the bug before you point at it.
Second, the same request with R-C-T-C-O applied: the schema, the constraints, and the output
format. The draft is better. Then find the bug in it, correct it, and check the row counts live.
The point is the failure modes from the last slide, happening on screen. Seeing a duplicate-row
bug come out of a confident draft sticks better than any list.
Ledger: the grain bug goes in Broke.

**Check:** This demo has no folder in the repo. Confirm where the prompts and the customer table live (WakeCountyFood has no customer table).
**Check:** Fill the ledger row for the grain bug from rehearsal (what it was, and the row counts before and after).

---

### 5.13 (old 96): Stop pasting your schema. Let it look things up.

**Visible text edits:**
  - [TextBox 4] "Every good answer in the last section, you hand-fed the context — and chores don't get done. MCP turns "here, let me paste my schema" into "go look it up yourself": the AI fetches context itself, always schema-aware, without you babysitting it." -> "Every good answer so far, you hand-fed the context. MCP turns "here, let me paste my schema" into "go look it up yourself": the AI fetches the context it needs, without you pasting it in."

**Notes:**
This is the next step in the day's thread. With vectors, we turned the data into something
searchable. With RAG, we found the right passages and handed them to the model. In the makeover,
we pasted the schema and the Severity values by hand. MCP lets the model go and get that context
itself.
That's convenient, and it changes the risk. A model that can look things up has a connection to
something, and that connection has permissions. Keep that in mind for the next few slides.

---

### 5.14 (old 98): MCP: USB-C for AI context (video)

**Visible text edits:** none

**Notes:**
Click to play; it runs about 24 seconds. Talk over it rather than reading the screen.
MCP is one standard way for an AI client to plug into servers. One client, many servers: a
database, Microsoft Learn, your files and runbooks. A server can offer three things:
- Tools: functions the AI can call, such as running a read-only query or describing a table.
- Resources: data the AI can read, such as docs, schema, or runbooks.
- Prompts: reusable prompt templates the server provides.
Asset: `images/mcp-usb-c.mp4` (poster `images/mcp-usb-c.png`), embedded play-on-click.

---

### 5.15 (old 99): Demo: the Microsoft Learn MCP server

**Visible text edits:**
  - [TextBox 14] "The hallucination failure mode from 5.1" -> "The hallucination failure mode from earlier in this section"
  - [TextBox 32] "The only difference is it can now look it up. That's MCP." -> delete

**Notes:**
Same model, same question, asked twice. Pick a question that depends on the SQL Server version.
Without MCP, the model guesses or hedges. With the Learn MCP server connected, it fetches the
documentation page and cites it.
A good question from today's material: "In SQL Server 2025, can I insert rows into a table that
has a vector index?" The answer is no: SQL Server 2025 ships the earlier vector index version,
which makes the table read-only. The newer version, which allows changes, is in Azure SQL
Database, Fabric, and Managed Instance on the Always-up-to-date policy. The room saw the
read-only behavior this morning.
This one is safe to run live: no credentials, and none of your data goes anywhere. The only
change between the two runs is that the model can now look things up.
Ledger: Worked, it looked up and cited the doc instead of guessing.

**Check:** This demo has no folder in the repo. Confirm the client (Claude Code or VS Code), that the Learn MCP server is configured on the presenting laptop, and the question you'll ask.
**Check:** It needs internet. Have screenshots of both runs in case the venue Wi-Fi fails.

---

### 5.16 (old 100): Database MCP servers: power and risk

**Visible text edits:**
  - [TextBox 1] "Database MCP servers — real power, real risk" -> "Database MCP servers: power and risk"
  - [TextBox 8] "Connect the AI to your actual metadata — tables, columns, procs, indexes. "Write me a proc" uses real names. The schema-blind problem? Gone." -> "Connect the AI to your actual metadata: tables, columns, procs, indexes. "Write me a proc" uses your names instead of guessed ones."
  - [TextBox 15] "The moment a server touches your DB: read-only? which credential? what's the blast radius? That's the cliffhanger for the build block." -> "Once a server touches your database: is it read-only? Which credential does it use? What's the blast radius?"

**Notes:**
The Learn server reads public docs. Point an MCP server at your database and two things change.
The model sees your tables, columns, procedures, and indexes, so the v1 problem from the
makeover goes away. And now something is connected to your database with a credential.
Three questions for any database MCP server: is it read-only, which login does it use, and what
is the most damage it could do?
One example: Microsoft's SQL MCP Server is built on Data API builder (1.7 and later). It's
driven by configuration, uses role-based access, and deliberately doesn't turn natural language
into SQL.
Next: the model stops only reading and starts running queries against your database.

---

### 5.17 (old 88): AI-assisted performance tuning, and its guardrails

**Visible text edits:**
  - [TextBox 32] "Inside of data governance boundaries, you may want to use an in-tenant copilot versus a public cloud’s. Regardless of where the language model lives, validate answers against your workload before applying them." -> delete

**Notes:**
Where it helps: Agent mode in SSMS or VS Code pulls the waits and plans itself, explains waits
you haven't seen before, and drafts index and rewrite candidates.
Give it the plan, not only the SQL. Optimization, refactoring, and diagnosis all improve when
the model sees the execution plan or wait stats along with the query.
Where to be careful: it can't see your data distribution or statistics, so treat every
suggestion as a hypothesis to test. Don't paste sensitive schema or PII into a public model;
an in-tenant tool is the safer choice inside governance boundaries. And it doesn't know your
SLAs or why that "redundant" index exists.
Next: an agent given a slow query and full access to the database.

**Check:** The left image on this slide was a placeholder in June. Swap in a real Copilot screenshot (03 or 04 from the SSMS shot list would work).

---

### 5.18 (old 89): Demo: Tuning a slow query via generative AI

**Visible text edits:** none

**Notes:**
Files: `src/demo/block4/perf-triage/10_slow_query.sql` (the slow query),
`20_capture_diagnostics.sql` (waits and the actual plan), `30_fixed_query.sql` (the tuned
version). Both prompts and the expected findings are in the folder's README.
Say this on stage before you start: Claude Code connects to the container as `sa`.
1. Run `10_slow_query.sql`. Read the business question aloud while it spins, about 58 seconds
   of CPU.
2. Prompt 1 (diagnose, change nothing): waits first, then the plan. It should find PAGELATCH_EX
   on top, then CXSYNC_PORT and CXSYNC_CONSUMER, and no PAGEIOLATCH, so not an I/O problem.
   The plan shows scans, two Index Spools, and DOP 8. About 362 logical reads against 58
   seconds of CPU: cheap reads, expensive query. Root cause: three non-SARGable predicates.
3. Prompt 2 (fix and prove it): date range instead of YEAR(), IN instead of LIKE, OUTER APPLY
   with a clean HSISID predicate. About 58,000 ms down to about 290 ms of CPU, same 6,256 rows,
   EXCEPT both ways returns nothing.
4. It also suggests an index. Decide that with numbers. On the demo container the vector index
   has made FoodInspectionViolation read-only, so that index can't be added now anyway.
Then say the uncomfortable part. Good work, done with the keys to everything. Next: the same
kind of agent inside SSMS, and how to give it its own identity and rules.
Ledger: the CPU numbers in Worked, "connected as sa" in Broke.
Workflow B in the README is the fallback when the agent must not touch the database.

**Check:** Fill the ledger row with the live CPU numbers.
**Check:** The subtitle box (TextBox 59) was the same color as the background in June. Make it visible or delete it in the generator.

---

### 5.19 (new): Agents in SSMS

**Visible text:**
- SSMS 22 has a Copilot Agent mode (GA in 22.10.2) that runs queries itself instead of only suggesting them.
- It's read-only by default.
- You can make it run as a lower-privilege user (EXECUTE AS; needs IMPERSONATE).
- You can give it rules per database: a CONSTITUTION.md or AGENTS.md stored as an extended property.
- Admins can turn Agent mode off by policy and limit which MCP servers it may use.

**Notes:**
GitHub Copilot in SSMS is GA since 22.4.1. Agent mode arrived in preview in 22.7 and is GA in
22.10.2. Agent mode runs the queries itself, after an approval prompt. Microsoft's docs say
plainly that the approval prompt is not a security boundary; SQL Server permissions are.
Read-only is the default. Writes need READ_WRITE set in mcp.json.
By default it runs as whoever is signed in. A CONSTITUTION.md on the database, stored as an
extended property, can name an `agentExecuteAsUser`, and SSMS then wraps every Copilot query in
EXECUTE AS that user. The signed-in user needs IMPERSONATE on it, or Copilot won't run queries in
that database at all.
Admins can disable Agent mode with the Visual Studio ADMX templates and restrict MCP servers
with an allow list in GitHub's Copilot policies.

Demo: `src/demo/block4/ssms-agent/`. Setup, prompts, and the full beat list are in its README.
Run `90_reset.sql` first so beat 1 starts clean. Live is about 8 minutes; screenshots (5.19a)
about 2.
- Beat 1, as you: ask for the Raleigh restaurants with the most critical violations in 2025.
  Show the approval prompt. Watch what it does with "critical": checks the Severity values, or
  guesses `'Critical'` like v2 of the makeover. Then ask it to create an index. Read-only
  mode shouldn't run it. Everything it did run, it ran as `sa`.
- Beat 2: run `10_constitution.sql`. Show `agentExecuteAsUser: CopilotReader`, the house rules
  (the same facts the makeover typed by hand), and the column DENY on inspector names.
- Beat 3, new chat: same question. It should use Priority and Priority Foundation unprompted and
  match `20_prove_it.sql` (TACOS MI TIERRA CALIENTE, 9). Ask for inspector names: Msg 230. Ask
  who it's running as: CopilotReader.
Finish with `90_reset.sql`. If Copilot misbehaves, run `20_prove_it.sql` to show the same checks
by hand.
Ledger: beat 1's handling of "critical"; beat 3's Priority values and Msg 230 in Worked.
This is the answer to the perf-triage demo: same kind of agent, but now its reach is something
you configured. Next: building your own guarded MCP server, then the guardrail stack.

**Check:** Live or screenshots. Live needs the time from the drop-if-long list (5.3, 5.8, 5.20).
**Check:** The three "Verify in rehearsal" items in the demo README: how the UI shows a statement READ_ONLY won't run; whether Copilot reads metadata as you or as CopilotReader; whether a new chat picks up the constitution without restarting SSMS.
**Check:** Fill the beat 1 ledger row: did it check the Severity values or guess 'Critical'?

---

### 5.19a (new, optional): Demo: Agent mode in SSMS (screenshots)

Only for the short version. The spec counts this as the 100th slide if it's used.

**Visible text:** up to 8 screenshots, captured in rehearsal, from
`slides/screenshots/ssms-agent/`:
`01-agent-mode.png`, `02-approval.png`, `03-critical-as-you.png`, `04-read-only-index.png`,
`05-constitution.png`, `06-critical-as-reader.png`, `07-denied.png`, `08-running-as.png`.

**Notes:**
Walk the shots in order, about 15 seconds each.
1 and 2: Agent picked in the mode dropdown, and the approval prompt on its first query. The
prompt confirms intent; it doesn't limit anything.
3: what it did with "critical" while running as us.
4: the CREATE INDEX it proposed and didn't run, because Agent mode is read-only by default.
5: the constitution, with `agentExecuteAsUser: CopilotReader` and the house rules.
6: same question, now using Priority and Priority Foundation with nobody typing them.
7: the inspector question hitting Msg 230. The rule in the constitution asks nicely; the
column DENY is what stops it.
8: running as CopilotReader, signed in as the presenter.

**Check:** Screenshots don't exist yet; Kevin captures them in rehearsal. Check each for a GitHub account name, email address, or server name before it goes on a slide.

---

### 5.20 (old 112): It's 50 lines, not magic

**Visible text edits:**
  - [TextBox 2] "In 5.2 you watched the AI fetch its own context. Here's the whole trick: instantiate a server, register one resource (the schema) and one tool (run a read-only query), wire a least-privilege connection." -> "You just watched the AI fetch its own context. Here's the whole trick: instantiate a server, register one resource (the schema) and one tool (run a read-only query), and wire a least-privilege connection."
  - [TextBox 7] "·  Scaffold-and-fill beats typing 200 lines live and praying." -> "·  Start from a scaffold and fill in the pieces."
  - [TextBox 9] "The tutorial teaches you to register a tool. Production teaches you to ship one safely." -> delete

**Notes:**
An MCP server for your database is small. Five steps: create the server and declare what it
offers; register the schema as a resource, read from INFORMATION_SCHEMA or the sys views;
register a run_select tool that runs a read-only query and returns rows; connect with a
parameterized, least-privilege login; add it to .mcp.json and confirm the client connects.
The tool's description is part of the prompt. A clear description is how the model knows when
and how to call it.
Registering a tool is the easy part. Making it safe is the next slide.
If the section is running long, skip this slide and go straight to the guardrail stack.

**Check:** Where the server code behind this slide and the 5.22 demo lives; it isn't in this repo.

---

### 5.21 (old 114): The guardrail stack

**Visible text edits:**
  - [TextBox 1] "The guardrail stack — not one check" -> "The guardrail stack: six layers"
  - [TextBox 38] "Any one layer can fail; the stack still holds. That's the difference between a demo and production." -> delete

**Notes:**
Six layers, because any one of them can fail.
Read-only by default: the model can't drop what its login can't drop. That's what CopilotReader
was in the SSMS demo, and what the perf-triage demo skipped by connecting as `sa`.
SELECT-only at the boundary: the server parses the statement and rejects anything else.
Caps and timeouts: a row cap and a query timeout, so one bad query can't take the server down.
Credential hygiene: secrets stay out of code and out of the prompt, and errors don't echo
connection strings.
Prompt injection: returned data can contain instructions. A violation comment is free text
someone else typed; an agent reading it reads whatever is in it.
An external hook: a Claude Code hook checks every tool call and doesn't trust the server.
Test that it blocks.
The next demo shows the stack refusing something.

---

### 5.22 (old 115): Demo: it works AND it refuses

**Visible text edits:**
  - [TextBox 30] "Show the refusal, not just the success — that's the credibility moment." -> delete

**Notes:**
Two halves, same server.
It works: ask a question in plain English. The AI calls run_select against the database, and
rows come back.
It refuses: ask for something destructive. The external hook blocks it before it reaches the
server, and the SELECT-only check would have caught it too.
Spend as long on the refusal as on the success. A guardrail you've only seen in a diagram is a
claim; one the room watched block a request is evidence.
Ledger: Worked, the guarded server refused the destructive request.

**Check:** This demo has no folder in the repo. Confirm where the server and hook live, which client runs it, and the exact destructive request you'll type.

---

### 5.23 (old 44): The most dangerous guardrail is the one nobody tests

**Visible text edits:**
  - [TextBox 4] "I run ~90 governance checks across my AI tooling. Prepping this talk I found one whose blocking rule had been silently dead for weeks — it looked like a guardrail and protected nothing. The most dangerous guardrail is the one everyone believes is working. Test that your 'no' actually fires." -> "I run about 90 governance checks across my AI tooling. Preparing this talk, I found one whose blocking rule had been silently dead for weeks. It looked like a guardrail and protected nothing. Test that your 'no' actually fires."

**Notes:**
I run about 90 checks across my AI tooling. While
preparing this talk I found one whose blocking rule had stopped working weeks earlier. Nothing
told me. It still looked like a guardrail, and it protected nothing.
That's the point right after a demo where a guardrail worked: guardrails fail too, quietly.
The refusal you just saw only counts because we tested it. Put "does the block still fire?" on
a schedule, the same way you test restores.
This one doesn't go on the ledger. It happened before today, not on screen.

**Check:** Jonathan: confirm the story details as you'll tell them (what the check was, how you found it). The deck has no more than what's on the slide.

---

### 5.24 (old 117): Model + context + guardrail + where users already are

**Visible text edits:**
  - [TextBox 4] "A model + your context + a guardrail + a place users already are. Once you see the recipe, you can invent the fifth yourself. This is how I run ~90 hooks across my setup — and two hard-won cautions: test that the guardrail actually fires, and watch the blast radius. A guardrail is code; it earns the same testing as the thing it guards." -> "A model, your context, a guardrail, and a place users already are. The SSMS demo followed that recipe: Copilot, a constitution, a low-privilege user, inside the tool DBAs already use. Two cautions I learned the hard way: test that the guardrail actually fires, and watch the blast radius."

**Notes:**
Every useful agent setup has the same four parts: a model, your context, a guardrail, and a
place your users already work. The SSMS demo had all four. Perf triage had three; the
guardrail was missing, which is why it ran as `sa`.
My two cautions: test that the guardrail fires, because I've had one that didn't. And know the
blast radius: what's the worst this login, this tool, this agent can do if it's wrong?
A guardrail is code, and it needs the same testing as the code it protects.
Next: what this section added to the ledger.

---

### 5.25 (new): Ledger, section 5 rows

**Visible text:** the two-column ledger, Worked and Broke. Rows from sections 1 to 4 stay on
the slide; the rows below are new and highlighted. Listed in the order the room saw them.

- Broke: Given the tables but not the Severity values, the model guessed `Severity = 'Critical'`, a value that doesn't exist. 0 rows. (Prompt makeover, v2)
- Broke: A naive join turned 5 violations into 165. (Prompt makeover, v3)
- Worked: With the schema, the Severity values, and the constraints, the same model wrote a correct query. (Prompt makeover, v4)
- Broke: **[fill]** the grain bug in the requirements-to-procedure demo.
- Worked: With the Learn MCP server, the model looked up and cited the documentation instead of guessing.
- Worked: The agent found the slow query's root cause and cut it from about 58,000 ms to about 290 ms of CPU, same result set. **[fill]** with the live numbers.
- Broke: It did that connected as `sa`.
- **[fill]** SSMS, as you: whether Agent mode checked the Severity values or guessed `'Critical'`.
- Worked: With the constitution in place, it used Priority and Priority Foundation with nobody typing them.
- Worked: Asked for inspector names, it hit a permission error from SQL Server (Msg 230), not a polite refusal.
- Worked: The guarded MCP server refused the destructive request.

**Notes:**
Read the new rows quickly; the room saw every one of them. Point out the pattern. The "Broke"
rows are mostly the model working from too little context or with too much access. The "Worked"
rows mostly came after someone supplied the context or set the limits: the Severity values, the
constitution, the low-privilege user, the SELECT-only server.
The guardrail story from 5.23 isn't here because it didn't happen today.
Next section: what to tell leadership, using this ledger as the evidence.

**Check:** Fill the three [fill] rows in rehearsal (grain bug, SSMS beat 1, perf-triage CPU numbers).

---

## Section 6: Talking to leadership (Jonathan)

### 6.0 (old 107): Talking to leadership

**Visible text edits:**
- [TextBox 4] "BUILD YOUR OWN TOOLS" -> "TALKING TO LEADERSHIP"

**Notes:**
"06" and "CHAPTER SIX" stay; they match the new order. This is the last section, and it's
the one people will use on Monday. All day the ledger has collected what worked and what
broke on screen. Now it becomes evidence for the conversation with your boss, including the
question every boss is asking: can agents replace the data team? We answer it with the
ledger, not with our opinions. Then we build the pitch for a pilot.

### 6.1 (new): The ledger, in full

**Visible text:**
Two columns, "Worked" and "Broke", one or two slides (builder's call). Rows grouped by
section:

Section 1: How these models work
- Worked: at temperature 0, the same prompt gave the same answer.
- Broke: at high temperature, the same prompt gave different answers each run.

Sections 2 and 3: Vectors
- Worked: violation comments about the same problem clustered together with no keywords in common.
- Worked: "rodent or pest activity in the kitchen" found roach, fly, and mouse comments that share none of those words with the question.
- Broke: an empty string doesn't come back as NULL. It fails the statement (Msg 31744), and in a batch UPDATE that one row fails the whole batch.
- Broke: once indexed, the table went read-only. Adding rows means drop the index, embed, rebuild.
- Broke: for the pest question, the index's top 10 matched the exact top 10 on 8 of 10 rows. Across 25 sample rows, recall was 0.97, and the worst single query was 0.70.

Section 4: RAG
- Worked: every one of 6 test questions found its runbook at rank 1. **[fill]** with the Foundry run.
- Worked: asked about something no runbook covers, the model said it didn't know instead of making something up. **[fill]** from the live run.
- Broke: for a question no runbook covers, retrieval still handed the model four chunks. Retrieval always returns its top k.
- Broke: the out-of-scope question's best match was nearly as close as a real answer's (0.595 vs 0.540), so distance alone can't tell "no answer" from "weak answer". **[fill]** with Foundry's numbers, or drop.

Section 5: Agents
- Broke: given the tables but not the real values, the model guessed `Severity = 'Critical'`, a value that doesn't exist; the query returned 0 rows.
- Broke: a naive join turned 5 rows into 165.
- Worked: with the schema, real values, and constraints, the same model wrote a correct query.
- Broke: **[fill]** the grain bug in the requirements-to-procedure demo.
- Worked: with the Learn MCP server, the model looked up and cited the real doc instead of guessing.
- Worked: the agent found the slow query's root cause and cut it from about 58,000 ms to about 290 ms of CPU with an identical result set. **[fill]** with the live numbers.
- Broke: it did that connected as `sa`.
- **[fill]** SSMS Agent mode, first run: Worked if it checked the real Severity values, Broke if it guessed `'Critical'`.
- Worked: with the constitution in place, it used `Priority` and `Priority Foundation` with nobody typing them.
- Worked: asked for inspector names, it hit a permission error from SQL Server (Msg 230), not a polite refusal.
- Worked: the guarded MCP server refused the destructive request.

**Notes:**
Everything here happened on screen today. No industry statistics, no hypotheticals. Don't
read every row; the room saw them. Point at three rows people will remember: the model guessing
'Critical', 5 rows becoming 165, and the agent doing good work while connected as `sa`. Then
ask the room what pattern they see in the right-hand column. Hold the answer for the next
slide. Before the session, resolve every **[fill]** row and drop any row whose demo didn't
run today: if a row didn't happen in front of this room, it doesn't belong here.

**Check:** Resolve all **[fill]** rows in rehearsal. The section 3 recall numbers were measured 2026-11-01 on 2,000 embedded comments; rerun `50_recall_check.sql` if the embedded set changes.

### 6.2 (new): Can agents replace the data team?

**Visible text:**
Two columns, drawn from the ledger.
- Left, "What the agents did well today": drafting queries, finding similar text, looking up docs, a first diagnosis of a slow query.
- Right, "What needed a person": knowing `'Critical'` isn't a real value; spotting 5 rows becoming 165; deciding whether 0.97 recall is good enough; noticing the agent ran as `sa`; owning the result when it's wrong.

**Notes:**
The answer comes from the ledger, not from us. Give the left column its due: the agents
changed how fast the work went, and pretending otherwise costs you credibility with the people
in 6.3. Then look at the Broke rows. Nearly every one needed someone who knew the data or the
system to notice it, and none of the agents flagged its own mistake. Ask the room which column
their job is in. That's the answer to take back to a boss who asks about replacing the team:
the work gets faster, and someone still has to know when it's wrong.

### 6.3 (old 32): The four people you're selling to

**Visible text edits:**
- [TextBox 15] "Convinced it'll leak PII or DROP a table. These people are often working for cybersecurity and can become your best ally." -> "Convinced it'll leak PII or DROP a table. These people often work in security and can become your best ally."
- [TextBox 22] "Lived through big data and blockchain. Skepticism earned, not irrational." -> "Lived through big data and blockchain. Their skepticism is earned."
- [TextBox 123] "Your job isn't to defeat them. Your job is to give each one the specific thing they need to say yes." -> delete

**Notes:**
You don't need to win an argument with any of these people. Give each one what they need to
say yes, and today gave you most of it. The True Believer gets a bounded pilot with a
measurement plan, so the budget has a direction. The Terrified get the guardrails from
section 5: read-only by default, a lower-privilege login, a guarded MCP server. Bring them in
early; security people make good allies. The Burned get the ledger, Broke column included,
which is evidence rather than a pitch. The people already using it get a sanctioned path,
because a flat "no" just means you stop hearing about it.

### 6.4 (old 33): The two ways AI initiatives die

**Visible text edits:**
- [TextBox 11] "First wrong answer in prod → project dead" -> "First wrong answer in prod kills the project"
- [TextBox 21] `"We can't use it — data-leak risk."` -> `"We can't use it. Data-leak risk."` (the box text includes the double quotes)
- [TextBox 32] "Don't sell magic. Sell leverage. Magic gets you one budget cycle. Leverage gets you a program." -> delete

**Notes:**
Over-promise first. "It'll write all our T-SQL" didn't survive today: the model guessed a
value that doesn't exist until it had the schema, the real values, and the constraints. If you
promise more than the ledger shows, the first wrong answer in production ends the project and
you own it. Over-fear fails more quietly: the team uses public tools anyway, and you lose
both the speed and the visibility. The way between them is to promise only what you can
measure, which is what the pilot pitch on the next slide is built around.

### 6.5 (merged 34+120): The pilot pitch

**Visible text:**
Title: The pilot pitch
1. The painful problem, in their units: hours, tickets, risk.
2. A small pilot: one table or one set of documents, one set of test questions.
3. How you'll measure it: recall and retrieval hits (you saw both today), plus the time it saves, measured in the pilot.
4. The risks and your guardrails, stated first.
5. The ask: time, budget, or access, and when you'll report back.

**Notes:**
This replaces two older slides that said much the same thing. Point 1: name the pain in the
boss's units, for example a three-hour ticket that takes 45 minutes with review. Point 2: pick
something boring and bounded, low-stakes and frequent, with a fixed timebox such as 30 days.
Point 3 is the part most pitches leave out, and you already have the measurement plan: recall
against exact search from section 3, retrieval hits from the section 4 test questions.
Point 4: lead with the risks, before anyone asks, and name the guardrails from section 5.
Point 5: ask for the next small step, never a platform.

Time saved wasn't measured on stage today (the perf-triage numbers are query CPU time, not staff time), which is why the slide puts it in the pilot.

### 6.6 (old 35): Bring the hard questions into the room early

**Visible text edits:**
- [TextBox 4] "You don't convince the boss by being the most excited person in the room — you convince them by being the most credible. The person who already thought about what could go wrong. Which is exactly what we do next: security." -> "The boss trusts the most credible person in the room, and that's rarely the most excited one. Be the person who has already thought about what could go wrong, and say it before anyone asks."

**Notes:**
The hard questions are coming either way: what happens when it's wrong, what data leaves the
building, who reviews the output. Raise them yourself and you set the terms. You have answers
from today. When it's wrong: the 'Critical' guess, and the test questions that would catch
it. What it can reach: the agent ran as `sa`, and section 5 showed how to run it as a
lower-privilege user instead. How good is good enough: 0.97 recall is a number someone has to
accept on purpose. Drop this slide if the section runs long.

### 6.7 (old 118): Your AI adoption roadmap

**Visible text edits:**
- [TextBox 19] "Propose the AUP. Build your first DB MCP server with guardrails. Pilot one DIY tool on one team." -> "Propose an AI use policy. Build your first DB MCP server with guardrails. Run one measured pilot: one table or one set of docs."
- [TextBox 28] "Vectors normal, AI-assisted ops routine, context layers standard. Your role shifts to governing AI-augmented systems." -> "Vector search and AI-assisted operations become routine. Your role shifts toward governing what the AI can see and do."

**Notes:**
Phase I is things you can do this week without asking anyone. The Learn MCP server needs no
credentials and sends none of your data. Phase II needs a sign-off: the AI use policy from
section 5, a database MCP server with the guardrails you saw, and one measured pilot built the
way 6.5 describes. Phase III is a direction; present it as one, without dates. The thread
through all three: every phase should leave you with evidence, the same kind as the ledger,
for the next conversation with leadership.

### 6.8 (old 121): Do one thing Monday. Have a result to show.

**Visible text edits:**
- [TextBox 4] "Do one thing Monday — the smallest useful thing from today — and have a result to show. That's how this goes from a conference you attended to a capability your team has. Pick your one thing before you leave the room." -> "Do one thing Monday, the smallest useful thing from today, and have a result to show. Pick your one thing before you leave the room."

**Notes:**
Ask everyone to pick one thing now, before the questions. Give them options from today:
compare exact and indexed search on one table and measure recall; write ten test questions
for your own runbooks; set up the Learn MCP server; draft the AI use policy; set SSMS Agent
mode to run as a lower-privilege user. Keep it small enough to finish. Whatever
result you get is your first ledger row.

### 6.9 (old 122): Questions? Let's talk.

**Visible text edits:**
- [TextBox 14] "Picking the right tool" -> "Running a vector or RAG pilot"

**Notes:**
Both of us take questions. The five prompts on the slide are starters if the room is quiet;
"where to start Monday" usually gets things going. Repeat each question before answering so
the whole room hears it. If a question needs a demo rerun or a long answer, offer to take it
at the break or after the session. Questions about a specific shop's data or policy are
better answered one on one.


### 6.10 (old 123): Thank You.

**Visible text edits:**
- Add one line under the names: "Slides and demo code: github.com/feaselkl/AI-at-the-Gates"

**Notes:**
Thank the room for the whole day, and thank the Day of Data Portland organizers and
volunteers. Our contact details are on the slide; invite people to reach out with what they
try on Monday, including what breaks. Remind them the demo scripts are in the repo with a
README per demo.

---

## All checks, in slide order

- **0.1:** Friday's break and lunch times (spec open item). The slides-and-code link is github.com/feaselkl/AI-at-the-Gates (also on 6.10).
- **0.2:** Jonathan confirms "the tooling I'm about to show you" still fits now that most of the old build-your-own-tools slides are cut.
- **1.3:** Kevin confirms this reading of the slide (the spec marks it as "my reading; Kevin to confirm").
- **2.4:** How you show king minus man plus woman in the Projector UI. I couldn't confirm it does vector arithmetic directly; if it doesn't, show it with a custom projection or describe it instead of demoing it.
- **2.4:** That the Projector's neighbor list is computed on the full vectors, not the 3D view, before saying "the neighbor list is the part to trust".
- **2.5:** In rehearsal, pick and note one specific comment whose neighbors share no keywords with it, so beat 4 doesn't depend on finding one live.
- **2.10:** Whether the Projector's neighbor list is approximate or exact. If it's exact, retitle the slide "You've already seen nearest-neighbor search" and drop "approximate" from the notes.
- **3.11:** 30_create_vector_index.sql drops and rebuilds both indexes; decide in rehearsal whether to run it live or only show it.
- **3.20:** Old 86 contradicted itself on whether a backup carries the external model's credentials. The merged text avoids the claim; confirm the restore behavior before answering that question on stage.
- **3.21:** The timings come from the comments in 20_generate_embeddings.sql; confirm they were Harrier runs on the laptop you'll present from.
- **3.22:** The empty-string row is on-screen only if the one-line call in the 3.11 notes is run live; if it isn't, drop the row.
- **3.22:** Recall numbers are from 2026-11-01 on the 2,000-row set; rerun 50_recall_check.sql before Friday and update this slide and 3.13 together.
- **4.6:** The scripts have no run without RAG. Decide how to show the left column (ask a chat model the same question cold, or talk through it).
- **4.8:** Kevin runs `04_eval.sql` against Foundry before Friday and fills in the numbers here and on 4.10.
- **4.10:** Confirm or drop each **[fill]** row after the Foundry run and rehearsal.
- **5.12:** This demo has no folder in the repo. Confirm where the prompts and the customer table live (WakeCountyFood has no customer table).
- **5.12:** Fill the ledger row for the grain bug from rehearsal (what it was, and the row counts before and after).
- **5.15:** This demo has no folder in the repo. Confirm the client (Claude Code or VS Code), that the Learn MCP server is configured on the presenting laptop, and the question you'll ask.
- **5.15:** It needs internet. Have screenshots of both runs in case the venue Wi-Fi fails.
- **5.17:** The left image on this slide was a placeholder in June. Swap in a real Copilot screenshot (03 or 04 from the SSMS shot list would work).
- **5.18:** Fill the ledger row with the live CPU numbers.
- **5.18:** The subtitle box (TextBox 59) was the same color as the background in June. Make it visible or delete it in the generator.
- **5.19:** Live or screenshots. Live needs the time from the drop-if-long list (5.3, 5.8, 5.20).
- **5.19:** The three "Verify in rehearsal" items in the demo README: how the UI shows a statement READ_ONLY won't run; whether Copilot reads metadata as you or as CopilotReader; whether a new chat picks up the constitution without restarting SSMS.
- **5.19:** Fill the beat 1 ledger row: did it check the Severity values or guess 'Critical'?
- **5.19a:** Screenshots don't exist yet; Kevin captures them in rehearsal. Check each for a GitHub account name, email address, or server name before it goes on a slide.
- **5.20:** Where the server code behind this slide and the 5.22 demo lives; it isn't in this repo.
- **5.22:** This demo has no folder in the repo. Confirm where the server and hook live, which client runs it, and the exact destructive request you'll type.
- **5.23:** Jonathan: confirm the story details as you'll tell them (what the check was, how you found it). The deck has no more than what's on the slide.
- **5.25:** Fill the three [fill] rows in rehearsal (grain bug, SSMS beat 1, perf-triage CPU numbers).
- **6.1:** Resolve all **[fill]** rows in rehearsal. The section 3 recall numbers were measured 2026-11-01 on 2,000 embedded comments; rerun `50_recall_check.sql` if the embedded set changes.
