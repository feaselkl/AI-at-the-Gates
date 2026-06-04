# Block 1 demos

These are the hands-on bits for [`outlines/Block1.md`](../../../outlines/Block1.md)
(sections 1.1–1.4). Everything here is **browser-based or a small local model** —
no SQL Server, no T-SQL. The database arrives in Block 4.

## At a glance

| Slide | Demo | What you need |
|-------|------|---------------|
| 1.1.3 | "Predict the next word" — audience guesses | nothing (a slide) |
| 1.2.2 | A neural network learning, visually | browser: [TensorFlow Playground](https://playground.tensorflow.org) |
| 1.2.3 | Text → tokens | browser: a tokenizer, e.g. [tiktokenizer](https://tiktokenizer.vercel.app) |
| 1.2.7 | Temperature changes output | local model — `temperature_demo.py` |
| 1.3.4 | Classic embeddings (king−man+woman) | browser: [Embedding Projector](https://projector.tensorflow.org) (built-in data) |
| 1.3.5 | Real clusters from our data | Embedding Projector + `embed_violations.py` output |
| 1.4.4 | "Nearest neighbor = close enough" | reuse the Projector from 1.3.5 |

## Browser demos (nothing to install)

- **TensorFlow Playground** — pick the two-clusters dataset, run it, watch the
  decision boundary form. Point: the rule was *learned*, not written.
- **Tokenizer** — paste a sentence; show it splitting into subword tokens; paste a
  rare/long word to show fragmentation. Sets up tokens + context windows.
- **Embedding Projector (classic)** — search `king`, show nearest neighbors, then
  the `king − man + woman ≈ queen` analogy. Directions carry meaning.

## Local demo: temperature (`temperature_demo.py`)

Reuses the Ollama you set up for Block 4 (see [`../../infra/ollama/`](../../infra/ollama/)).
Harrier is embedding-only, so pull a small **chat** model:

```bash
ollama pull llama3.2:1b          # tiny; fine on CPU or a small GPU (e.g. AMD 780M)
python3 temperature_demo.py
```

Runs the same non-SQL prompt at temperature 0 (same answer every time) and ~1
(varies). Great contrast with embeddings, which are deterministic.

## Local demo: real-data clusters (`embed_violations.py` → Embedding Projector)

Embeds Wake County violation comments with **Harrier** (the same model Block 4
uses) and writes two TSV files for the Projector. This previews semantic search
on the very dataset Block 4 queries — without a database.

```bash
# one-time: extract the CSV (see data/ note in ../../infra/docker/README.md) and
# have Ollama + the harrier model running (../../infra/ollama/)
python3 embed_violations.py                 # -> vectors.tsv, metadata.tsv (3000 comments)

# no Ollama handy? validate the file format first:
python3 embed_violations.py --dry-run
```

Then at <https://projector.tensorflow.org>:
1. Click **Load**.
2. "Load a TSV file of vectors" → `vectors.tsv`.
3. "Load a TSV file of metadata" → `metadata.tsv`.
4. Set **Color by → severity**; click a point to see semantically similar comments.

You'll see comments about temperature/cold-holding cluster together, pests
elsewhere, cleanliness elsewhere — meaning, not keywords.

## Notes

- The generated `vectors.tsv` / `metadata.tsv` are git-ignored (regenerable; can
  be several MB). Re-run the script to recreate them.
- Both Python scripts use only the standard library — no `pip install`.
