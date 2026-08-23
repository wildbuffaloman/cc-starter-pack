# retro

> Run a retrospective — routes to the correct protocol based on session mode and review scope

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
/retro optional: project name, or review scope for vault management — weekly, monthly, quarterly, annual
```

## Files

- `SKILL.md`

