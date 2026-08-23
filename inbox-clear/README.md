# inbox-clear

> Clear your inbox folder using the GTD decision tree — classify every item, propose a destination for each, and execute only what you approve.

**Version:** 0.0.1

## Installation

This skill ships as part of **cc-starter-pack**. Install the pack, not the skill:

```bash
git clone https://github.com/wildbuffaloman/cc-starter-pack.git
cd cc-starter-pack
./install.sh
```

**Updating an existing install:** a plain `./install.sh` **skips** every skill you already have and reports nothing wrong, so an update silently does nothing. Run `./install.sh force` to overwrite your copies with the current versions.

## Usage

Invoke in Claude Code:

```
/inbox-clear                    # classify the whole inbox
/inbox-clear "Note Title.md"    # classify a single note
```

Phase 1 writes a manifest of checkbox decisions and changes nothing. Tick the boxes you approve, then tell Claude to execute.

## Files

- `SKILL.md`
