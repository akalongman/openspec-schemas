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
assert_contains "$(cd "$P" && openspec schema validate spec-driven-longish 2>&1)" "is valid" "the schema validates"
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
if cmp -s "$HOME/projects/tsmu/tsmulms/openspec/schemas/spec-driven-longish/templates/summary.md" "$S/templates/summary.md"; then _pass; else _fail "summary template kept"; fi

finish
