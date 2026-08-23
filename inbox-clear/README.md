# inbox-clear

> Clear your inbox folder using the GTD decision tree — classify every item, propose a destination for each, and execute only what you approve.

**Version:** 0.0.1

## Installation

Ships in [cc-starter-pack](https://github.com/wildbuffaloman/cc-starter-pack):

```bash
git clone https://github.com/wildbuffaloman/cc-starter-pack.git
cd cc-starter-pack
./install.sh          # add 'force' to overwrite an existing copy
```

Or copy just this directory into `~/.claude/skills/inbox-clear/`.

## Usage

Invoke in Claude Code:

```
/inbox-clear                    # classify the whole inbox
/inbox-clear "Note Title.md"    # classify a single note
```

Phase 1 writes a manifest of checkbox decisions and changes nothing. Tick the boxes you approve, then tell Claude to execute.

## Files

- `SKILL.md`
