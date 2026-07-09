#!/usr/bin/env bash
# Install cc-starter-pack skills into ~/.claude/skills/
# Usage:
#   ./install.sh           -> copy skills, skip any already installed (recommended)
#   ./install.sh force      -> overwrite (use to pick up updated skills)
#   ./install.sh symlink   -> symlink (live updates via git pull)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude/skills"
mkdir -p "$TARGET"
SKILLS="session-close context permissions retro extract skill-create project-create deep-research deep-planning fermi-decomposition"
MODE="${1:-copy}"
for s in $SKILLS; do
  if [[ -e "$TARGET/$s" && "$MODE" != "force" ]]; then
    echo "SKIP: $TARGET/$s already exists — run './install.sh force' to overwrite, or remove manually"
    continue
  fi
  [[ "$MODE" == "force" && -e "$TARGET/$s" ]] && rm -rf "$TARGET/$s"
  if [[ "$MODE" == "symlink" ]]; then
    ln -s "$SCRIPT_DIR/$s" "$TARGET/$s"
    echo "symlinked: $TARGET/$s"
  else
    cp -r "$SCRIPT_DIR/$s" "$TARGET/$s"
    echo "copied: $TARGET/$s"
  fi
done
echo ""
echo "Done. Restart Claude Code to pick up the skills."
echo "Then try: /project-create, /deep-planning — they're now available."
