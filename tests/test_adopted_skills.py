from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADOPTED = ROOT / "adopted-skills"
EXPECTED = ("i-have-adhd", "ponytail", "ponytail-audit", "ponytail-review")


def read_frontmatter(skill_path: Path) -> list[str]:
    text = skill_path.read_text()
    assert text.startswith("---\n")
    end = text.index("\n---\n", 4)
    return text[4:end].splitlines()


def test_adopted_skill_names_and_manual_only_frontmatter():
    assert sorted(path.name for path in ADOPTED.iterdir() if path.is_dir()) == sorted(EXPECTED)
    for name in EXPECTED:
        lines = read_frontmatter(ADOPTED / name / "SKILL.md")
        assert f"name: {name}" in lines
        assert "disable-model-invocation: true" in lines


def test_adopted_skill_descriptions_require_explicit_invocation():
    for name in EXPECTED:
        text = (ADOPTED / name / "SKILL.md").read_text()
        assert f"Manual-only: invoke /{name} explicitly; do not infer it." in text

def test_every_adopted_skill_has_codex_manual_only_policy():
    for name in EXPECTED:
        sidecar = (ADOPTED / name / "agents" / "openai.yaml").read_text()
        assert "allow_implicit_invocation: false" in sidecar


def test_adopted_skills_contain_no_runtime_extensions():
    forbidden = {"hooks", "extensions", "plugins", "plugin.json"}
    for path in ADOPTED.rglob("*"):
        assert path.name not in forbidden
