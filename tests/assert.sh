#!/usr/bin/env bash
# Minimal plain-bash test helpers, mirroring tests/assert.sh in the
# maintainer's private dotfiles. Kept self-contained so this repository's
# tests do not depend on those dotfiles.

TESTS_RUN=0
TESTS_FAILED=0
TMPDIRS=()

_pass() { TESTS_RUN=$((TESTS_RUN + 1)); }
_fail() {
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf 'FAIL: %s\n' "$1" >&2
}

assert_contains() { # haystack needle msg
    case "$1" in
        *"$2"*) _pass ;;
        *) _fail "$3 (missing '$2')" ;;
    esac
}

assert_not_contains() { # haystack needle msg
    case "$1" in
        *"$2"*) _fail "$3 (unexpectedly found '$2')" ;;
        *) _pass ;;
    esac
}

assert_symlink_to() { # path expected_target msg
    if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then
        _pass
    else
        _fail "$3 (expected symlink to '$2', got '$(readlink "$1" 2>/dev/null || echo 'not a symlink')')"
    fi
}

assert_regular_file() { # path msg
    if [ -f "$1" ] && [ ! -L "$1" ]; then _pass; else _fail "$2 (not a regular file: $1)"; fi
}

assert_dir() { # path msg
    if [ -d "$1" ] && [ ! -L "$1" ]; then _pass; else _fail "$2 (not a real directory: $1)"; fi
}

assert_not_symlink() { # path msg
    if [ -e "$1" ] && [ ! -L "$1" ]; then _pass; else _fail "$2 (expected a real path, not a symlink: $1)"; fi
}

finish() {
    printf '\n%d run, %d failed\n' "$TESTS_RUN" "$TESTS_FAILED" >&2
    for d in "${TMPDIRS[@]-}"; do [ -n "$d" ] && rm -rf "$d"; done
    [ "$TESTS_FAILED" -eq 0 ]
}

assert_eq() { # actual expected msg
    if [ "$1" = "$2" ]; then _pass; else _fail "$3 (expected '$2', got '$1')"; fi
}

assert_file() { # path msg
    if [ -e "$1" ] || [ -L "$1" ]; then _pass; else _fail "$2 (no such path: $1)"; fi
}

assert_nofile() { # path msg
    if [ -e "$1" ] || [ -L "$1" ]; then _fail "$2 (path exists: $1)"; else _pass; fi
}
