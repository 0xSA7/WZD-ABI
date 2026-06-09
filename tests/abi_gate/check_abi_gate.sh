#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
#
# check_abi_gate.sh - Fingerprint and version pairing check for the WZD ABI.
#
# Enforces docs/ABI-CONTRACT.md section 6: a change in the preprocessed
# header surface must travel with a WzdAbiVersion.h bump in the same PR,
# plus a section 8 changelog entry.
#
# Usage:
#   bash tests/abi_gate/check_abi_gate.sh           verify against the golden
#   bash tests/abi_gate/check_abi_gate.sh --bless   regenerate the golden
#
# Exit codes: 0 pass, 1 fail or error.

set -euo pipefail

GOLDEN="tests/abi_gate/ABI_FINGERPRINT.txt"
HEADERS="WzdIoctl.h WzdTelemetry.h"

note() { printf 'abi-gate: %s\n' "$*"; }
die()  { printf 'abi-gate: FAIL: %s\n' "$*" >&2; exit 1; }

command -v git       >/dev/null 2>&1 || die "git is required"
command -v gcc       >/dev/null 2>&1 || die "gcc is required"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || die "run this script from inside the WZD-ABI repository"
cd "$ROOT"
[ -f WzdAbiVersion.h ] || die "WzdAbiVersion.h not found at the repository root"

version_triple() {
    major="$(sed -n 's/^#define[[:space:]]*WZD_ABI_VERSION_MAJOR[[:space:]]\+\([0-9][0-9]*\).*/\1/p' WzdAbiVersion.h)"
    minor="$(sed -n 's/^#define[[:space:]]*WZD_ABI_VERSION_MINOR[[:space:]]\+\([0-9][0-9]*\).*/\1/p' WzdAbiVersion.h)"
    patch="$(sed -n 's/^#define[[:space:]]*WZD_ABI_VERSION_PATCH[[:space:]]\+\([0-9][0-9]*\).*/\1/p' WzdAbiVersion.h)"
    [ -n "$major" ] && [ -n "$minor" ] && [ -n "$patch" ] \
        || die "could not parse the version triple from WzdAbiVersion.h"
    printf '%s.%s.%s' "$major" "$minor" "$patch"
}

header_fp() {
    f="$1"
    [ -f "$f" ] || die "missing shared header: $f"
    gcc -E -P -std=c11 -I. "$f" | sha256sum | awk '{print $1}'
}

write_golden() {
    {
        printf '# WZD ABI fingerprint golden, contract %s\n' "$(version_triple)"
        printf '# Regenerate ONLY with: bash tests/abi_gate/check_abi_gate.sh --bless\n'
        printf 'version %s\n' "$(version_triple)"
        for f in $HEADERS; do
            printf '%s %s\n' "$f" "$(header_fp "$f")"
        done
    } > "$GOLDEN"
}

case "${1:-verify}" in
    --bless)
        write_golden
        note "golden regenerated: $GOLDEN"
        note "valid only inside a PR that bumps WzdAbiVersion.h and updates docs/ABI-CONTRACT.md section 8"
        ;;
    verify)
        [ -f "$GOLDEN" ] || die "golden file $GOLDEN is missing; run: bash tests/abi_gate/check_abi_gate.sh --bless"

        golden_version="$(sed -n 's/^version[[:space:]]\+//p' "$GOLDEN" | head -n 1)"
        [ -n "$golden_version" ] || die "golden file has no version line"

        live_version="$(version_triple)"
        if [ "$live_version" != "$golden_version" ]; then
            note "version moved: golden=$golden_version live=$live_version"
        fi

        changed=0
        for f in $HEADERS; do
            pat="${f//./\\.}"
            golden_fp="$(sed -n "s/^${pat}[[:space:]]\+//p" "$GOLDEN" | head -n 1)"
            [ -n "$golden_fp" ] || die "golden file has no entry for $f"
            live_fp="$(header_fp "$f")"
            if [ "$live_fp" != "$golden_fp" ]; then
                changed=1
                note "fingerprint drift in $f"
                printf 'abi-gate:   golden  %s\nabi-gate:   live    %s\n' "$golden_fp" "$live_fp"
            fi
        done

        if [ "$changed" -eq 1 ] && [ "$live_version" = "$golden_version" ]; then
            die "ABI surface moved without a WzdAbiVersion.h bump; see docs/ABI-CONTRACT.md sections 2 and 6"
        fi
        if [ "$changed" -eq 1 ]; then
            die "ABI surface moved: bless the golden and add the section 8 entry in this same PR"
        fi

        note "OK: fingerprints match the golden (contract $live_version)"
        ;;
    *)
        die "unknown argument: $1 (no arguments verifies, --bless regenerates the golden)"
        ;;
esac
