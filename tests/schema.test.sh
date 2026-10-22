#!/usr/bin/env bash
# Checks for the openspec-schemas repository. Run from any directory:
#   bash tests/schema.test.sh
# A passing run prints "N run, 0 failed" and exits 0.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"
# shellcheck source=/dev/null
. "$HERE/assert.sh"

assert_eq "$(cat "$REPO/UPSTREAM")" "spec-driven@1.14.3" "UPSTREAM names the merged upstream version"
assert_contains "$(cat "$REPO/README.md")" "openspec/schemas/spec-driven-longish" "README explains vendoring by copy"
assert_contains "$(cat "$REPO/README.md")" ".local/share/openspec/schemas" "README explains the user-level link"
assert_contains "$(cat "$REPO/README.md")" "SOURCE" "README explains the lineage sidecar"
assert_contains "$(head -1 "$REPO/CHANGELOG.md")" "# Changelog" "CHANGELOG has a title"
assert_contains "$(cat "$REPO/CHANGELOG.md")" "## 2026-10-20" "CHANGELOG has the first dated entry"
assert_contains "$(cat "$REPO/LICENSE")" "MIT License" "MIT license"
assert_eq "$(python3 -I -c 'import json,sys;print(json.load(open(sys.argv[1]))["name"])' "$REPO/.github/rulesets/protect-main.json")" "protect-main" "ruleset definition parses and names protect-main"

S="$REPO/schemas/spec-driven-longish"

# mk_project: create a throwaway OpenSpec project that selects
# spec-driven-longish and carries a copy of this repository's schemas/.
# Sets P to its path and registers it for finish to remove.
mk_project() {
    P="$(mktemp -d)"
    TMPDIRS+=("$P")
    mkdir -p "$P/openspec/specs" "$P/openspec/changes"
    printf 'schema: spec-driven-longish\n' > "$P/openspec/config.yaml"
    cp -R "$REPO/schemas" "$P/openspec/schemas"
}

mk_project
# Mask the user-level schema directory so only the project copy can answer.
assert_contains "$(cd "$P" && XDG_DATA_HOME="$P/xdg-data" openspec schema validate spec-driven-longish 2>&1)" "is valid" "the schema validates"
assert_eq "$(python3 -I -c 'import yaml,sys;print(" ".join(a["id"] for a in yaml.safe_load(open(sys.argv[1]))["artifacts"]))' "$S/schema.yaml")" "proposal specs design tasks summary" "artifact order"
assert_eq "$(python3 -I -c 'import yaml,sys;print(" ".join(yaml.safe_load(open(sys.argv[1]))["apply"]["requires"]))' "$S/schema.yaml")" "tasks summary" "apply requires tasks and summary"
assert_eq "$(python3 -I -c 'import yaml,sys;print(" ".join(next(a for a in yaml.safe_load(open(sys.argv[1]))["artifacts"] if a["id"]=="summary")["requires"]))' "$S/schema.yaml")" "proposal design tasks" "summary is the terminal artifact"

# The templates are compared byte for byte with the installed package only
# when the installed CLI is the version UPSTREAM names. Another version
# skips these comparisons with a notice.
upstream_version="$(cat "$REPO/UPSTREAM")"
upstream_version="${upstream_version#*@}"
installed_version="$(openspec --version)"
if [ "$installed_version" = "$upstream_version" ]; then
    UP="$(npm root -g)/@fission-ai/openspec/schemas/spec-driven"
    for t in spec.md design.md tasks.md; do
        if cmp -s "$UP/templates/$t" "$S/templates/$t"; then _pass; else _fail "$t equals upstream"; fi
    done
    # proposal.md is upstream's file with one section appended at the end,
    # so upstream's bytes are a prefix of it.
    if cmp -s -n "$(wc -c < "$UP/templates/proposal.md")" "$UP/templates/proposal.md" "$S/templates/proposal.md"; then _pass; else _fail "upstream's proposal.md kept byte for byte"; fi
else
    printf 'notice: installed CLI %s differs from UPSTREAM, template comparison skipped\n' "$installed_version" >&2
fi
assert_contains "$(cat "$S/templates/proposal.md")" "## Scope & Decisions" "proposal template has Scope & Decisions"
for h in "## Why" "## What Changes" "## Capabilities" "## Impact"; do assert_contains "$(cat "$S/templates/proposal.md")" "$h" "proposal keeps upstream heading $h"; done
assert_eq "$(grep '^## ' "$S/templates/summary.md" | paste -sd '|' -)" "## Problem|## Solution|## Business Outcome|## Risks & Timing" "summary template has exactly the instruction's four sections, in order"

# instruction_block ARTIFACT FIRST [LAST]: print the lines of ARTIFACT's
# instruction (apply's comes from apply.instruction) from the line containing
# FIRST to the next blank line or the end of the instruction. With LAST, the
# block runs on through the line that starts with LAST (leading spaces
# ignored) and to the next blank line after it. A missing instruction or
# marker prints a line naming both instead, so two missing blocks never
# compare equal.
instruction_block() {
    python3 -I - "$S/schema.yaml" "$@" <<'EOF'
import sys

import yaml

path, artifact, first = sys.argv[1:4]
last = sys.argv[4] if len(sys.argv) > 4 else None
try:
    with open(path, encoding="utf-8") as fh:
        doc = yaml.safe_load(fh)
    if artifact == "apply":
        text = doc["apply"]["instruction"]
    else:
        text = next(a["instruction"] for a in doc["artifacts"] if a["id"] == artifact)
    lines = text.split("\n")
    start = next(i for i, line in enumerate(lines) if first in line)
    end = start
    if last is not None:
        end = next(i for i in range(start, len(lines)) if lines[i].lstrip().startswith(last))
    while end + 1 < len(lines) and lines[end + 1].strip():
        end += 1
    print("\n".join(lines[start:end + 1]))
except Exception:
    print("missing: %r in the %s instruction" % (first, artifact))
EOF
}
table_block() { instruction_block "$1" "Render exactly this table:" "- Render every row"; }
sanctioned_edits_block() { instruction_block specs "Sanctioned direct edits"; }

for tok in composer artisan Academic tsmulms LMS-BACKEND course staging.yml .claude/; do assert_not_contains "$(cat "$S/schema.yaml")" "$tok" "no project token: $tok"; done
assert_eq "$(python3 -I -c 'import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))["description"])' "$S/schema.yaml")" "Spec-driven workflow with a mandatory clarification interview and a stakeholder summary: proposal, specs, design, tasks, summary" "description"
# the table block runs from the line 'Render exactly this table:' through the bullet starting 'Render every row'; extracted from the tasks instruction and the apply instruction
assert_eq "$(table_block tasks)" "$(table_block apply)" "tasks table specified identically in tasks and apply"
assert_contains "$(cat "$S/schema.yaml")" "500 characters" "500-character rule present"
assert_contains "$(cat "$S/schema.yaml")" "openspec validate --specs --strict" "apply last-mile strict validation"
assert_contains "$(instruction_block apply "**Validation**:" | tr -s '[:space:]' ' ')" "does not block completion: list it under Follow-ups" \
    "apply validation leaves a corpus finding the change did not introduce to Follow-ups"
assert_contains "$(cat "$S/schema.yaml")" "skip_specs: true" "skip_specs explained"
for c in "retitle" "Purpose" "normalization" "workflow or CI specs"; do assert_contains "$(sanctioned_edits_block)" "$c" "sanctioned direct edit: $c"; done
assert_contains "$(cat "$S/schema.yaml")" "pull request" "wording covers pull requests"
assert_contains "$(cat "$S/schema.yaml")" "the project's area headings" "capability map wording is neutral"
assert_not_contains "$(cat "$S/schema.yaml")" "Why this is mandatory" "rationale paragraph cut (item 22)"

finish
