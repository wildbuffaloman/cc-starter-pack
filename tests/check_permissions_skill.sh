#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="$SCRIPT_DIR/../permissions/SKILL.md"

if grep -Fqi 'display contents' "$SKILL"; then
  echo "FAIL: permissions skill must not request whole settings files" >&2
  exit 1
fi

for required in \
  'version: "0.1.2"' \
  'display ONLY' \
  '`allow`, `deny`, `ask`, `defaultMode`, `additionalDirectories`' \
  '`autoMode.environment`' \
  'Never print `env`, `apiKeyHelper`, hook `command` strings' \
  '`KEY`, `TOKEN`, `SECRET`, or `PASSWORD`' \
  'case-insensitive' \
  'at every nesting depth' \
  'list such keys by name with their values replaced by `[redacted]`' \
  'renders only permission-related keys'; do
  if ! grep -Fq "$required" "$SKILL"; then
    echo "FAIL: missing permissions skill instruction: $required" >&2
    exit 1
  fi
done

echo "PASS: permissions skill checks"
