#!/usr/bin/env python3
"""
rag.py  -- Block 5.3 RAG demo, the "simple Python app" variant.

Same idea as the T-SQL example, but the app drives it:
  --index : read docs/*.md -> chunk -> embed (Foundry) -> store in SQL Server
  --ask "<question>" : embed the question -> retrieve closest chunks from SQL
                       (VECTOR_DISTANCE) -> ask the Foundry chat model -> print a
                       grounded, cited answer.

SQL Server is the vector store; Microsoft Foundry supplies the embedding + chat
models (no local GPU). Retrieval uses exact kNN (the corpus is tiny -> no ANN
index needed; see Block 4).

Config comes from environment variables (see .env.example). Dependencies:
  pip install pyodbc      # plus the Microsoft ODBC Driver 18 for SQL Server
Everything else is the Python standard library.
"""
import argparse
import glob
import json
import os
import sys
import urllib.request

import pyodbc

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(HERE, "..", "docs")

# --- config (env vars; see .env.example) -------------------------------------
ENDPOINT      = os.environ.get("FOUNDRY_ENDPOINT", "https://<resource>.openai.azure.com").rstrip("/")
API_KEY       = os.environ.get("FOUNDRY_API_KEY", "")
EMBED_DEPLOY  = os.environ.get("FOUNDRY_EMBED_DEPLOYMENT", "text-embedding-3-small")
CHAT_DEPLOY   = os.environ.get("FOUNDRY_CHAT_DEPLOYMENT", "gpt-4o-mini")
EMBED_APIVER  = os.environ.get("FOUNDRY_EMBED_API_VERSION", "2024-02-01")
CHAT_APIVER   = os.environ.get("FOUNDRY_CHAT_API_VERSION", "2024-10-21")
EMBED_DIM     = int(os.environ.get("EMBED_DIM", "1536"))
SQL_CONN      = os.environ.get(
    "SQL_CONNECTION_STRING",
    "DRIVER={ODBC Driver 18 for SQL Server};SERVER=localhost,1433;"
    "UID=sa;PWD=WakeCounty!2025;Encrypt=yes;TrustServerCertificate=yes",
)
CHUNK_SIZE, OVERLAP = 800, 120   # characters


def _post(url, body):
    req = urllib.request.Request(
        url, data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json", "api-key": API_KEY},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read())


def embed(texts):
    """Return a list of embedding vectors (lists of floats) for the input texts."""
    url = f"{ENDPOINT}/openai/deployments/{EMBED_DEPLOY}/embeddings?api-version={EMBED_APIVER}"
    data = _post(url, {"input": texts})
    return [row["embedding"] for row in data["data"]]


def chat(messages, temperature=0.2):
    url = f"{ENDPOINT}/openai/deployments/{CHAT_DEPLOY}/chat/completions?api-version={CHAT_APIVER}"
    data = _post(url, {"messages": messages, "temperature": temperature})
    return data["choices"][0]["message"]["content"]


def chunk(text, size=CHUNK_SIZE, overlap=OVERLAP):
    step = max(1, size - overlap)
    return [text[i:i + size] for i in range(0, len(text), step) if text[i:i + size].strip()]


def connect(database=None):
    cs = SQL_CONN + (f";DATABASE={database}" if database else "")
    return pyodbc.connect(cs, autocommit=True)


def ensure_schema():
    with connect("master") as cx:
        cx.execute("IF DB_ID('DbaDocs') IS NULL CREATE DATABASE DbaDocs;")
    with connect("DbaDocs") as cx:
        cx.execute("""
            IF OBJECT_ID('dbo.KbChunkPy') IS NULL
            CREATE TABLE dbo.KbChunkPy (
                ChunkId    INT IDENTITY PRIMARY KEY,
                DocName    NVARCHAR(200) NOT NULL,
                ChunkOrder INT NOT NULL,
                ChunkText  NVARCHAR(MAX) NOT NULL,
                Embedding  VECTOR(%d) NULL
            );""" % EMBED_DIM)


def cmd_index(_args):
    ensure_schema()
    paths = sorted(glob.glob(os.path.join(DOCS_DIR, "*.md")))
    if not paths:
        sys.exit(f"No docs found in {DOCS_DIR}")
    with connect("DbaDocs") as cx:
        cx.execute("TRUNCATE TABLE dbo.KbChunkPy;")
        total = 0
        for path in paths:
            name = os.path.basename(path)
            chunks = chunk(open(path, encoding="utf-8").read())
            vectors = embed(chunks)                       # batch the whole doc
            for i, (c, v) in enumerate(zip(chunks, vectors)):
                cx.execute(
                    "INSERT INTO dbo.KbChunkPy (DocName, ChunkOrder, ChunkText, Embedding) "
                    "VALUES (?, ?, ?, CAST(? AS VECTOR(%d)))" % EMBED_DIM,
                    name, i, c, json.dumps(v),
                )
            total += len(chunks)
            print(f"  indexed {name}: {len(chunks)} chunks")
        print(f"Done. {total} chunks across {len(paths)} docs.")


def cmd_ask(args):
    qv = embed([args.question])[0]
    with connect("DbaDocs") as cx:
        rows = cx.execute(
            "SELECT TOP (?) DocName, ChunkText, "
            "       VECTOR_DISTANCE('cosine', CAST(? AS VECTOR(%d)), Embedding) AS distance "
            "FROM dbo.KbChunkPy WHERE Embedding IS NOT NULL "
            "ORDER BY distance" % EMBED_DIM,
            args.k, json.dumps(qv),
        ).fetchall()
    if not rows:
        sys.exit("No chunks found -- run with --index first.")
    context = "\n\n".join(f"[{r.DocName}]\n{r.ChunkText}" for r in rows)
    messages = [
        {"role": "system", "content":
            "You are a DBA assistant. Answer ONLY from the provided context. Cite the "
            "source document name in square brackets. If the answer is not in the context, "
            "say you do not know."},
        {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {args.question}"},
    ]
    print("\n=== ANSWER ===\n" + chat(messages))
    print("\n=== SOURCES (retrieved chunks) ===")
    for r in rows:
        print(f"  {r.DocName}  (distance {r.distance:.4f})")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("index", help="chunk + embed docs/*.md into SQL Server")
    a = sub.add_parser("ask", help="answer a question via RAG")
    a.add_argument("question")
    a.add_argument("-k", type=int, default=4, help="how many chunks to retrieve (default 4)")
    args = p.parse_args()
    {"index": cmd_index, "ask": cmd_ask}[args.cmd](args)


if __name__ == "__main__":
    main()
