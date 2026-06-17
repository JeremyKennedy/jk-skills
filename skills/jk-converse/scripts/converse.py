#!/usr/bin/env python3
"""converse — async multi-agent conversation over a shared JSONL file.

A single conversation lives in one JSONL file. Each line is a record:

    {"type": "meta",   "topic": "...", "context": "...", "created": "...", "participants": [...]}
    {"type": "msg",    "seq": 1, "from": "agent-1", "ts": "...", "body": "..."}
    {"type": "cursor", "agent": "agent-1", "seq": 1, "ts": "..."}

`msg` records are the conversation. `cursor` records track how far each named
participant has read, so "new messages since you last looked" is exact and
survives repeated waits without posting. The file is the single source of
truth — no sidecar state. A short-lived `<file>.lock` guards read-modify-write.

Participants are arbitrary named strings (`--as <name>`); any number may join.

Commands:
    init   <file> [--topic T] [--context C] [--participants a,b] [--force]
    post   <file> --as NAME [--message M | --file F | -]   (body via stdin if omitted)
    wait   <file> --as NAME [--timeout SECONDS]            (aliases: watch, listen)
    read   <file> --as NAME [--peek]                       (new messages, no post)
    log    <file>                                          (render full transcript)

Exit codes: 0 ok / delivered, 2 wait timed out with nothing new, 1 error.
"""

import argparse
import fcntl
import json
import os
import sys
import time
from datetime import datetime, timezone


# ─── low-level file + lock helpers ──────────────────────────────────────────

def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


class FileLock:
    """Exclusive flock on `<path>.lock`, usable as a context manager."""

    def __init__(self, path):
        self.lockpath = path + ".lock"
        self._fd = None

    def __enter__(self):
        self._fd = open(self.lockpath, "w")
        fcntl.flock(self._fd, fcntl.LOCK_EX)
        return self

    def __exit__(self, *_exc):
        if self._fd is not None:
            fcntl.flock(self._fd, fcntl.LOCK_UN)
            self._fd.close()
            self._fd = None


def read_records(path):
    if not os.path.exists(path):
        return []
    recs = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                recs.append(json.loads(line))
            except json.JSONDecodeError:
                continue  # tolerate partial/corrupt trailing lines
    return recs


def append_record(path, rec):
    line = json.dumps(rec, ensure_ascii=False)
    with open(path, "a", encoding="utf-8") as f:
        f.write(line + "\n")
        f.flush()
        os.fsync(f.fileno())


# ─── conversation model ─────────────────────────────────────────────────────

def messages(records):
    return [r for r in records if r.get("type") == "msg"]


def meta_of(records):
    for r in records:
        if r.get("type") == "meta":
            return r
    return None


def max_seq(records):
    return max((m.get("seq", 0) for m in messages(records)), default=0)


def cursor_for(records, agent):
    seen = 0
    for r in records:
        if r.get("type") == "cursor" and r.get("agent") == agent:
            seen = max(seen, r.get("seq", 0))
    return seen


def new_for(records, agent):
    """Messages from *other* participants that `agent` has not yet seen."""
    seen = cursor_for(records, agent)
    return [
        m for m in messages(records)
        if m.get("seq", 0) > seen and m.get("from") != agent
    ]


def set_cursor(path, agent, seq):
    append_record(path, {"type": "cursor", "agent": agent, "seq": seq, "ts": now_iso()})


# ─── rendering ──────────────────────────────────────────────────────────────

def render_new(msgs):
    if not msgs:
        return "No new messages."
    n = len(msgs)
    out = ["%d new message%s:" % (n, "" if n == 1 else "s"), ""]
    for m in msgs:
        out.append("─── [%s] seq %s · %s ───" % (m.get("from", "?"), m.get("seq", "?"), m.get("ts", "")))
        out.append(m.get("body", "").rstrip("\n"))
        out.append("")
    return "\n".join(out).rstrip("\n")


def render_transcript(records):
    meta = meta_of(records)
    out = []
    if meta:
        out.append("# Conversation: %s" % meta.get("topic", "(untitled)"))
        if meta.get("context"):
            out.append("")
            out.append(meta["context"])
        if meta.get("participants"):
            out.append("")
            out.append("Participants: %s" % ", ".join(meta["participants"]))
    for m in messages(records):
        out.append("")
        out.append("---")
        out.append("")
        out.append("## %s (seq %s · %s)" % (m.get("from", "?"), m.get("seq", "?"), m.get("ts", "")))
        out.append("")
        out.append(m.get("body", "").rstrip("\n"))
    return "\n".join(out).strip() + "\n"


def read_body(args):
    if args.message is not None:
        return args.message
    if args.body_file:
        if args.body_file == "-":
            return sys.stdin.read()
        with open(args.body_file, encoding="utf-8") as f:
            return f.read()
    # fall back to stdin (the common case for multi-line bodies)
    return sys.stdin.read()


# ─── commands ───────────────────────────────────────────────────────────────

def cmd_init(args):
    path = args.file
    if os.path.exists(path) and os.path.getsize(path) > 0 and not args.force:
        sys.stderr.write("error: %s already exists (use --force to overwrite)\n" % path)
        return 1
    participants = [p.strip() for p in (args.participants or "").split(",") if p.strip()]
    with FileLock(path):
        with open(path, "w", encoding="utf-8") as f:
            rec = {
                "type": "meta",
                "topic": args.topic or "",
                "context": args.context or "",
                "participants": participants,
                "created": now_iso(),
            }
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
            f.flush()
            os.fsync(f.fileno())
    print("Initialized conversation at %s" % path)
    if args.topic:
        print("Topic: %s" % args.topic)
    return 0


def cmd_post(args):
    path = args.file
    if not os.path.exists(path):
        sys.stderr.write("error: %s does not exist — run `init` first\n" % path)
        return 1
    body = read_body(args)
    if not body.strip():
        sys.stderr.write("error: empty message body\n")
        return 1
    with FileLock(path):
        records = read_records(path)
        seen_before = cursor_for(records, args.as_)
        seq = max_seq(records) + 1
        append_record(path, {
            "type": "msg", "seq": seq, "from": args.as_, "ts": now_iso(),
            "body": body.rstrip("\n"),
        })
        # messages that arrived from others while we were composing
        new = [
            m for m in messages(records)
            if m.get("seq", 0) > seen_before and m.get("from") != args.as_
        ]
        set_cursor(path, args.as_, seq)  # we've now seen everything through our own post
    print("Posted as %s (seq %d)." % (args.as_, seq))
    print()
    print(render_new(new))
    return 0


def _drain(path, agent, peek=False):
    """Return (new_messages, advanced) under lock; advance cursor unless peek."""
    with FileLock(path):
        records = read_records(path)
        new = new_for(records, agent)
        if new and not peek:
            set_cursor(path, agent, max_seq(records))
    return new


def cmd_read(args):
    path = args.file
    if not os.path.exists(path):
        sys.stderr.write("error: %s does not exist\n" % path)
        return 1
    new = _drain(path, args.as_, peek=args.peek)
    print(render_new(new))
    return 0


def cmd_wait(args):
    path = args.file
    if not os.path.exists(path):
        sys.stderr.write("error: %s does not exist\n" % path)
        return 1

    # Check first — a reply may already be waiting. This is the whole point:
    # never block on a message that has already arrived.
    new = _drain(path, args.as_, peek=False)
    if new:
        print(render_new(new))
        return 0

    timeout = args.timeout or 0
    deadline = (time.monotonic() + timeout) if timeout > 0 else None
    interval = max(0.1, min(args.interval, 5.0))
    last_mtime = os.path.getmtime(path)

    while True:
        if deadline is not None:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                sys.stderr.write("No new messages (timed out after %gs).\n" % timeout)
                return 2
            sleep_for = min(interval, remaining)
        else:
            sleep_for = interval
        time.sleep(sleep_for)

        try:
            mtime = os.path.getmtime(path)
        except OSError:
            continue
        if mtime == last_mtime:
            continue
        last_mtime = mtime
        new = _drain(path, args.as_, peek=False)
        if new:
            print(render_new(new))
            return 0


def cmd_log(args):
    path = args.file
    if not os.path.exists(path):
        sys.stderr.write("error: %s does not exist\n" % path)
        return 1
    sys.stdout.write(render_transcript(read_records(path)))
    return 0


# ─── argument parsing ───────────────────────────────────────────────────────

def build_parser():
    p = argparse.ArgumentParser(prog="converse", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="command", required=True)

    pi = sub.add_parser("init", help="create a new conversation file")
    pi.add_argument("file")
    pi.add_argument("--topic", default="")
    pi.add_argument("--context", default="")
    pi.add_argument("--participants", default="", help="comma-separated expected participant names")
    pi.add_argument("--force", action="store_true", help="overwrite an existing file")
    pi.set_defaults(func=cmd_init)

    pp = sub.add_parser("post", help="append a message and report any new messages")
    pp.add_argument("file")
    pp.add_argument("--as", dest="as_", required=True, metavar="NAME")
    pp.add_argument("--message", "-m", default=None, help="message body (else --file or stdin)")
    pp.add_argument("--file", "-f", dest="body_file", default=None,
                    help="read body from this path ('-' for stdin)")
    pp.set_defaults(func=cmd_post)

    pw = sub.add_parser("wait", aliases=["watch", "listen"],
                        help="block until a new message arrives")
    pw.add_argument("file")
    pw.add_argument("--as", dest="as_", required=True, metavar="NAME")
    pw.add_argument("--timeout", type=float, default=0,
                    help="seconds to wait (0 or omitted = indefinitely)")
    pw.add_argument("--interval", type=float, default=1.0,
                    help="poll interval in seconds (default 1.0)")
    pw.set_defaults(func=cmd_wait)

    pr = sub.add_parser("read", help="show new messages without posting")
    pr.add_argument("file")
    pr.add_argument("--as", dest="as_", required=True, metavar="NAME")
    pr.add_argument("--peek", action="store_true", help="do not advance read cursor")
    pr.set_defaults(func=cmd_read)

    pl = sub.add_parser("log", help="render the full transcript as markdown")
    pl.add_argument("file")
    pl.set_defaults(func=cmd_log)

    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
