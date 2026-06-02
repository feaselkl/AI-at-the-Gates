#!/usr/bin/env python3
"""
embed_violations.py  (Block 1, demo 1.3.5)

Generate `vectors.tsv` + `metadata.tsv` from the Wake County food-inspection
violation comments, for loading into the TensorFlow Embedding Projector
(https://projector.tensorflow.org -> "Load"). Lets you SHOW embeddings and
semantic clusters in the browser -- no SQL Server, no database at all.

Embeddings come from the Harrier model served by your local Ollama (the same
model Block 4 uses in SQL Server), so the two blocks share one embedding space.

Prerequisites:
  - Ollama running with the `harrier` model (see ../../infra/ollama/).
  - The violations CSV extracted from its .7z (see the data/ note in the
    docker README): data/Food_Inspection_Violations.csv

Usage:
  python3 embed_violations.py                 # 3000 comments -> vectors.tsv, metadata.tsv
  python3 embed_violations.py --limit 1500    # smaller/faster cloud
  python3 embed_violations.py --dry-run        # validate the pipeline with NO Ollama
                                               # (writes tiny placeholder vectors)

Only the Python standard library is used -- nothing to pip install.
"""
import argparse
import csv
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CSV = REPO_ROOT / "data" / "Food_Inspection_Violations.csv"
SCRIPT_DIR = Path(__file__).resolve().parent

# Increase the CSV field-size limit: the Comments column is long free text.
csv.field_size_limit(10_000_000)


def parse_args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--csv", type=Path, default=DEFAULT_CSV, help="path to Food_Inspection_Violations.csv")
    p.add_argument("--text-col", default="COMMENTS", help="CSV column to embed (default: COMMENTS)")
    p.add_argument("--limit", type=int, default=3000, help="max rows to embed (default: 3000)")
    p.add_argument("--batch", type=int, default=64, help="embeddings per Ollama request (default: 64)")
    p.add_argument("--model", default="harrier", help="Ollama model name (default: harrier)")
    p.add_argument("--ollama", default="http://127.0.0.1:11434", help="Ollama base URL")
    p.add_argument("--out", type=Path, default=SCRIPT_DIR, help="output directory")
    p.add_argument("--max-label", type=int, default=200, help="truncate metadata text to N chars")
    p.add_argument("--no-dedup", action="store_true", help="keep duplicate comments")
    p.add_argument("--dry-run", action="store_true", help="skip Ollama; write placeholder vectors to test the format")
    return p.parse_args()


def read_rows(csv_path, text_col, limit, dedup, max_label):
    """Return a list of {text, label, severity, code} dicts."""
    with open(csv_path, newline="", encoding="utf-8-sig") as fh:
        reader = csv.reader(fh)
        header = [h.strip().upper() for h in next(reader)]
        idx = {name: i for i, name in enumerate(header)}
        tcol = idx.get(text_col.upper())
        if tcol is None:
            sys.exit(f"ERROR: column '{text_col}' not found. Available: {', '.join(header)}")
        sev_i, code_i = idx.get("SEVERITY"), idx.get("VIOLATIONCODE")

        rows, seen = [], set()
        for rec in reader:
            text = rec[tcol].strip()
            if not text:
                continue
            if dedup:
                if text in seen:
                    continue
                seen.add(text)
            rows.append({
                "text": text,
                "label": _clean(text, max_label),
                "severity": _clean(rec[sev_i], 60) if sev_i is not None else "",
                "code": _clean(rec[code_i], 60) if code_i is not None else "",
            })
            if len(rows) >= limit:
                break
    return rows


def _clean(s, maxlen):
    """Collapse whitespace and truncate -- metadata TSV cells must not contain tabs/newlines."""
    s = " ".join((s or "").split())
    return s[:maxlen]


def embed_batch(ollama, model, texts):
    """POST /api/embed and return a list of embedding vectors."""
    payload = json.dumps({"model": model, "input": texts}).encode("utf-8")
    req = urllib.request.Request(f"{ollama}/api/embed", data=payload,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read())
    except urllib.error.URLError as e:
        sys.exit(f"ERROR calling Ollama at {ollama}: {e}\n"
                 f"Is Ollama running and is the '{model}' model installed? "
                 f"See ../../infra/ollama/.")
    embeddings = data.get("embeddings")
    if not embeddings or len(embeddings) != len(texts):
        sys.exit(f"ERROR: Ollama returned {len(embeddings or [])} embeddings for {len(texts)} inputs.")
    return embeddings


def main():
    args = parse_args()
    if not args.csv.exists():
        sys.exit(f"ERROR: {args.csv} not found. Extract it from the .7z first (see data/ note in the docker README).")

    rows = read_rows(args.csv, args.text_col, args.limit, not args.no_dedup, args.max_label)
    print(f"Collected {len(rows)} comments from {args.csv.name} (column {args.text_col}).")
    if not rows:
        sys.exit("ERROR: no non-empty comments found.")

    vectors = []
    if args.dry_run:
        print("DRY RUN: writing placeholder 8-dim vectors (no Ollama call).")
        for i, _ in enumerate(rows):
            vectors.append([float(i % 7), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
    else:
        for start in range(0, len(rows), args.batch):
            chunk = [r["text"] for r in rows[start:start + args.batch]]
            vectors.extend(embed_batch(args.ollama, args.model, chunk))
            print(f"  embedded {min(start + args.batch, len(rows))}/{len(rows)}", end="\r", flush=True)
        print()

    if len(vectors) != len(rows):
        sys.exit(f"ERROR: got {len(vectors)} vectors for {len(rows)} rows.")

    args.out.mkdir(parents=True, exist_ok=True)
    vec_path, meta_path = args.out / "vectors.tsv", args.out / "metadata.tsv"
    with open(vec_path, "w", encoding="utf-8") as vf:
        for vec in vectors:
            vf.write("\t".join(f"{x:.6f}" for x in vec) + "\n")
    with open(meta_path, "w", encoding="utf-8") as mf:
        mf.write("comment\tseverity\tviolation_code\n")          # header (required for multi-column metadata)
        for r in rows:
            mf.write(f"{r['label']}\t{r['severity']}\t{r['code']}\n")

    dim = len(vectors[0])
    print(f"Wrote {vec_path}  ({len(vectors)} rows x {dim} dims)")
    print(f"Wrote {meta_path} ({len(rows)} rows + header)")
    print("Load both at https://projector.tensorflow.org -> Load. Color by 'severity'.")


if __name__ == "__main__":
    main()
