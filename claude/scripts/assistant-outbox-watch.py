import json
import sys
import time

outbox_path = "/Users/camen/Documents/notes/work/outbox.jsonl"
session_id = json.load(open("/Users/camen/Documents/notes/work/mine.json"))["assistant"]["sessionId"]
once = "--once" in sys.argv
seen_texts = set(argument for argument in sys.argv[1:] if argument != "--once")

while True:
    printed = False
    try:
        lines = open(outbox_path).read().splitlines()
    except OSError:
        lines = []
    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if entry.get("sessionId") != session_id:
            continue
        text = entry.get("text", "")
        key = entry.get("id") or text
        if key in seen_texts:
            continue
        seen_texts.add(key)
        print(text.replace("\n", " / "), flush=True)
        printed = True
    if once and printed:
        break
    time.sleep(2)
