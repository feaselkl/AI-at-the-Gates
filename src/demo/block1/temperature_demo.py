#!/usr/bin/env python3
"""
temperature_demo.py  (Block 1, demo 1.2.7)

Show what `temperature` does to an LLM's output, using a small LOCAL chat model
served by Ollama -- offline, no SQL Server, no cloud account. Runs the same
(non-SQL) prompt at temperature 0 and temperature ~1, a couple of times each.

The teaching point:
  - temperature 0  -> greedy decoding -> the SAME answer every run (deterministic)
  - temperature ~1 -> sampling        -> a DIFFERENT answer most runs (creative)

This is the generation-side randomness knob. Note it does NOT exist for
embeddings (those are deterministic) -- a nice contrast to set up 1.3.

Prerequisites:
  - Ollama running (see ../../infra/ollama/).
  - A small CHAT model pulled. Harrier is embedding-only, so use e.g.:
        ollama pull llama3.2:1b
    (llama3.2:1b is tiny -- fine on CPU or a small GPU like an AMD 780M.)

Usage:
  python3 temperature_demo.py
  python3 temperature_demo.py --model llama3.2:1b --runs 2
  python3 temperature_demo.py --prompt "Write a one-line slogan for a coffee shop."

Standard library only.
"""
import argparse
import json
import sys
import urllib.error
import urllib.request

DEFAULT_PROMPT = "Suggest a fun, punny name for a taco food truck. Answer with just the name."


def parse_args():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--model", default="llama3.2:1b", help="Ollama chat model (default: llama3.2:1b)")
    p.add_argument("--prompt", default=DEFAULT_PROMPT, help="prompt to run")
    p.add_argument("--runs", type=int, default=2, help="runs per temperature (default: 2)")
    p.add_argument("--temps", default="0,1", help="comma-separated temperatures (default: 0,1)")
    p.add_argument("--ollama", default="http://127.0.0.1:11434", help="Ollama base URL")
    return p.parse_args()


def generate(ollama, model, prompt, temperature):
    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": temperature},
    }).encode("utf-8")
    req = urllib.request.Request(f"{ollama}/api/generate", data=payload,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read()).get("response", "").strip()
    except urllib.error.URLError as e:
        sys.exit(f"ERROR calling Ollama at {ollama}: {e}\n"
                 f"Is Ollama running and is the '{model}' chat model installed? "
                 f"Try: ollama pull {model}")


def main():
    args = parse_args()
    temps = [float(t) for t in args.temps.split(",")]
    print(f"Model: {args.model}   Prompt: {args.prompt!r}\n")
    for temp in temps:
        label = "deterministic" if temp == 0 else "creative / varied"
        print(f"=== temperature = {temp}  ({label}) ".ljust(60, "="))
        for run in range(1, args.runs + 1):
            print(f"  run {run}: {generate(args.ollama, args.model, args.prompt, temp)}")
        print()
    print("Notice: temp 0 repeats the same answer; higher temp varies each run.")


if __name__ == "__main__":
    main()
