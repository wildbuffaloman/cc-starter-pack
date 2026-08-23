# extract

> Smart-fetch and extract structured value from any vault note or URL — standalone content extraction following the Content Extraction convention. Supports single note, URL, and batch folder modes.

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
/extract note filename, URL, folder path, or 'batch' for INBOX
```

## Files

- `SKILL.md`

