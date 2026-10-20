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

finish
