# skill-create

> Create a new Claude Code skill — guided conversation to define the skill's purpose, triggers, steps, and rules, then generate and install the SKILL.md file.

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
/skill-create skill name or description of what the skill should do
```

## Files

- `SKILL.md`

