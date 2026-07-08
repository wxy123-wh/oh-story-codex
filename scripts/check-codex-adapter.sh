#!/usr/bin/env bash
# check-codex-adapter.sh — deterministic checks for the Codex-only plugin surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "required file missing: $1"; }
assert_path() { [ -e "$1" ] || fail "required path missing: $1"; }
assert_grep() { grep -Eq "$1" "$2" || fail "$3 ($2)"; }
assert_no_grep() { ! grep -Eq "$1" "$2" || fail "$3 ($2)"; }

PYBIN=""
for candidate in python3 python py; do
  if "$candidate" -c "" >/dev/null 2>&1; then
    PYBIN="$candidate"
    break
  fi
done
[ -n "$PYBIN" ] || fail "Python interpreter not found"

cd "$REPO_ROOT"

echo "Codex-only plugin check"
echo "======================="
echo "Repo: $REPO_ROOT"

CODEX_DIR="skills/story-setup/references/codex"
PLUGIN_JSON=".codex-plugin/plugin.json"

assert_file "$PLUGIN_JSON"
assert_file "$CODEX_DIR/AGENTS.md.tmpl"
assert_file "$CODEX_DIR/hooks/hooks.json"
assert_file "$CODEX_DIR/hooks/story_codex_hook.py"
assert_path "$CODEX_DIR/agents"

"$PYBIN" - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path(".codex-plugin/plugin.json").read_text(encoding="utf-8"))
assert manifest["name"] == "oh-story-claudecode"
assert manifest["skills"] == "./skills/"
assert "Codex" in manifest["description"]
assert manifest["interface"]["displayName"]
assert manifest["interface"]["shortDescription"]
assert manifest["interface"]["longDescription"]
assert manifest["interface"]["developerName"]
assert manifest["interface"]["category"]
assert len(manifest["interface"].get("defaultPrompt", [])) <= 3
PY

"$PYBIN" -m json.tool "$CODEX_DIR/hooks/hooks.json" >/dev/null
"$PYBIN" - <<'PY'
from pathlib import Path
compile(Path('skills/story-setup/references/codex/hooks/story_codex_hook.py').read_text(encoding='utf-8'), 'story_codex_hook.py', 'exec')
PY

echo "  OK manifest, JSON, and Python syntax"

HOOK_PY="$CODEX_DIR/hooks/story_codex_hook.py"
assert_grep 'sys\.stdin\.buffer\.read' "$HOOK_PY" "Codex hook must read stdin as UTF-8 bytes"
assert_grep 'sys\.stdout\.buffer\.write' "$HOOK_PY" "Codex hook must write stdout as UTF-8 bytes"
if grep -qE 'sys\.stdin\.read\(\)|sys\.stdout\.write\(' "$HOOK_PY"; then
  fail "Codex hook must not use text-mode sys.stdin.read()/sys.stdout.write()"
fi
if grep -nE '\.read_text\(' "$HOOK_PY" | grep -qv 'encoding='; then
  fail "every Codex hook read_text() must pass encoding='utf-8'"
fi

echo "  OK UTF-8 stdio + file reads"

assert_grep 'def prose_net_findings' "$HOOK_PY" "Codex hook must carry the light prose net"
assert_grep 'def find_changed_prose_files' "$HOOK_PY" "Codex Stop sweep must discover git-changed prose"
assert_grep 'def continuity_findings' "$HOOK_PY" "Codex hook must carry the continuity backstop"

echo "  OK prose and continuity backstops"

"$PYBIN" - <<'PY'
import tomllib
from pathlib import Path
expected = {
    'chapter-extractor', 'character-designer', 'consistency-checker',
    'narrative-writer', 'story-architect', 'story-explorer', 'story-researcher',
}
read_only = {'chapter-extractor', 'consistency-checker', 'story-explorer'}
found = set()
for path in sorted(Path('skills/story-setup/references/codex/agents').glob('*.toml')):
    data = tomllib.loads(path.read_text(encoding='utf-8'))
    for key in ('name', 'description', 'developer_instructions'):
        assert data.get(key), f'{path}: missing {key}'
    name = data['name']
    instructions = data['developer_instructions']
    assert path.name == f'{name}.toml', f'{path}: filename/name mismatch'
    assert '.codex/skills/story-setup/references/agent-references/' in instructions
    assert 'agent_type' in instructions, f'{path}: missing Codex agent_type guidance'
    assert 'subagent_type' not in instructions, f'{path}: leaked non-Codex subagent_type wording'
    assert '.claude/' not in instructions and '.opencode/' not in instructions, f'{path}: leaked non-Codex reference path'
    assert 'unknown agent_type' in instructions, f'{path}: missing runtime fallback guidance'
    if name in read_only:
        assert data.get('sandbox_mode') == 'read-only', f'{path}: expected read-only sandbox'
    found.add(name)
assert found == expected, found
PY

echo "  OK Codex custom-agent TOML"

"$PYBIN" - "$CODEX_DIR/hooks/hooks.json" "$CODEX_DIR/hooks/story_codex_hook.py" <<'PY'
import json, sys
from pathlib import Path
hooks = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["hooks"]
all_hooks = [h for arr in hooks.values() for blk in arr for h in blk["hooks"]]
assert all_hooks, "no launcher commands found"
for h in all_hooks:
    c = h["command"]
    assert '[ -f "$HOOK" ] || exit 0' in c, f"launcher missing no-op guard: {c[:80]}"
    assert 'CODEX_PROJECT_DIR="$PROJECT_ROOT" "$PYBIN" "$HOOK"' in c, f"launcher must propagate root to Python: {c[:80]}"
    assert "CLAUDE_PROJECT_DIR" not in c, f"launcher leaked non-Codex env fallback: {c[:80]}"
    w = h.get("commandWindows")
    assert w, f"hook missing commandWindows: {c[:60]}"
    assert "story_codex_hook.py" in w, f"commandWindows must invoke the hook: {w}"
    for posixism in ("${", "$(", "[ -f", "for PYBIN", "; do ", "&& break"):
        assert posixism not in w, f"commandWindows must be cmd.exe-safe (found {posixism!r}): {w}"
    assert c.split()[-1] == w.split()[-1], f"command/commandWindows event mismatch: {c.split()[-1]} vs {w.split()[-1]}"
hook_py = Path(sys.argv[2]).read_text(encoding="utf-8")
assert "Path(__file__)" in hook_py and "_deployed_root_from_file" in hook_py
assert "CLAUDE_PROJECT_DIR" not in hook_py
PY

echo "  OK launcher root propagation + no-op guard + cmd.exe commandWindows"

assert_grep '\$story-setup|\$story-long-write|/skills' "$CODEX_DIR/AGENTS.md.tmpl" "Codex AGENTS template must mention skill invocation"
assert_grep '\.codex/agents/\*\.toml' "$CODEX_DIR/AGENTS.md.tmpl" "Codex AGENTS template must mention custom agent location"
assert_grep '\.codex/hooks\.json' "$CODEX_DIR/AGENTS.md.tmpl" "Codex AGENTS template must mention hooks location"
assert_grep 'target_cli: codex' skills/story-setup/SKILL.md "story-setup must document codex target_cli"
assert_grep '\.codex/agents|\.codex/hooks\.json' skills/story-review/SKILL.md "story-review must check Codex agents"
assert_no_grep 'OpenCode|OpenClaw|Claude Code|opencode|openclaw|\.agents/skills|\.claude/agents|\.opencode/agents|subagent_type' README.md "README must be Codex-only"

echo "  OK Codex docs/instruction anchors"
echo ""
echo "OK: Codex-only plugin checks passed"
