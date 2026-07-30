"""Tests for converse.py — the structured async conversation engine."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

CONVERSE = Path(__file__).resolve().parent.parent / "skills" / "jk-converse" / "scripts" / "converse.py"


def converse(*args):
    """Run converse.py with the given arguments, return (code, stdout, stderr)."""
    r = subprocess.run(
        [sys.executable, str(CONVERSE), *args],
        capture_output=True, text=True, timeout=10,
    )
    return r.returncode, r.stdout, r.stderr


@pytest.fixture
def convfile():
    """Temporary conversation JSONL file."""
    fd, path = tempfile.mkstemp(suffix=".jsonl", prefix="converse_test_")
    os.close(fd)
    yield path
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass
    lock = path + ".lock"
    try:
        os.unlink(lock)
    except FileNotFoundError:
        pass


class TestInit:
    def test_init_creates_file(self, convfile):
        code, out, err = converse("init", convfile, "--topic", "Test", "--context", "Context", "--participants", "a,b")
        assert code == 0, f"init failed: {err}"
        assert os.path.exists(convfile)
        with open(convfile) as f:
            lines = f.readlines()
        assert len(lines) >= 1
        meta = json.loads(lines[0])
        assert meta["type"] == "meta"

    def test_init_no_participants_ok(self, convfile):
        code, out, err = converse("init", convfile, "--topic", "Test", "--context", "Ctx")
        assert code == 0, f"init failed: {err}"


class TestBroadcast:
    def test_broadcast_visible_to_all(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b")
        converse("post", convfile, "--as", "a", "-m", "hello from a")
        # Both a and b should see new messages
        code, out, err = converse("read", convfile, "--as", "b")
        assert code == 0
        assert "hello from a" in out


class TestDirected:
    def test_directed_only_to_target(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b,c")
        converse("post", convfile, "--as", "a", "--to", "b", "-m", "secret for b")
        # b should see it
        code, out, err = converse("read", convfile, "--as", "b")
        assert "secret for b" in out
        # c should not
        code, out, err = converse("read", convfile, "--as", "c")
        assert "secret for b" not in out


class TestWait:
    def test_wait_returns_immediately_when_pending(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b")
        converse("post", convfile, "--as", "a", "-m", "msg1")
        # wait should return immediately since there's a pending message
        code, out, err = converse("wait", convfile, "--as", "b", "--timeout", "5")
        assert code == 0
        assert "msg1" in out

    def test_wait_timeout_when_nothing_new(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b")
        code, out, err = converse("wait", convfile, "--as", "b", "--timeout", "2")
        assert code == 2  # timeout exit code


class TestJoin:
    def test_join_skips_backlog(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b")
        converse("post", convfile, "--as", "a", "-m", "old msg")
        # join after the post
        code, out, err = converse("join", convfile, "--as", "b")
        assert code == 0
        # b should not see the old message
        code, out, err = converse("read", convfile, "--as", "b")
        assert "old msg" not in out

    def test_join_with_digest(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b")
        converse("post", convfile, "--as", "a", "-m", "old msg")
        code, out, err = converse("join", convfile, "--as", "b", "--digest", "1")
        assert code == 0
        # digest shows the primer but backlog is still skipped
        assert "old msg" in out
        code, out, err = converse("read", convfile, "--as", "b")
        assert "old msg" not in out


class TestDigest:
    def test_digest_shows_last_per_agent(self, convfile):
        converse("init", convfile, "--topic", "T", "--context", "C", "--participants", "a,b")
        converse("post", convfile, "--as", "a", "-m", "a1")
        converse("post", convfile, "--as", "b", "-m", "b1")
        converse("post", convfile, "--as", "a", "-m", "a2")
        code, out, err = converse("digest", convfile, "--each", "1")
        assert code == 0
        # Last message from each agent
        assert "a2" in out
        assert "b1" in out
        assert "a1" not in out


class TestLog:
    def test_log_renders_transcript(self, convfile):
        converse("init", convfile, "--topic", "Test Topic", "--context", "Test Ctx", "--participants", "a,b")
        converse("post", convfile, "--as", "a", "-m", "hello")
        code, out, err = converse("log", convfile)
        assert "Conversation: Test Topic" in out
        assert "hello" in out


class TestRoundTrip:
    def test_two_participant_conversation(self, convfile):
        converse("init", convfile, "--topic", "Scope", "--context", "Widget refactor", "--participants", "proposer,reviewer")

        # Proposer posts
        code, out, err = converse("post", convfile, "--as", "proposer", "-m", "I propose X.")
        assert code == 0

        # Reviewer reads and responds with --wait (should return immediately)
        code, out, err = converse("post", convfile, "--as", "reviewer", "-m", "I disagree: Y is better.", "--wait")
        assert code == 0
        assert "I propose X." in out  # new messages shown

        # Proposer reads
        code, out, err = converse("read", convfile, "--as", "proposer")
        assert "I disagree: Y is better." in out

        # Mutual confirmation
        converse("post", convfile, "--as", "proposer", "-m", "I confirm this exact scope:\n1. Extract WidgetStore\n2. Keep existing name")
        code, out, _ = converse("post", convfile, "--as", "reviewer", "-m", "I confirm this exact scope:\n1. Extract WidgetStore\n2. Keep existing name")
        assert code == 0


class TestScriptCompiles:
    def test_converse_compiles(self):
        with open(CONVERSE) as f:
            import ast
            ast.parse(f.read(), str(CONVERSE))
