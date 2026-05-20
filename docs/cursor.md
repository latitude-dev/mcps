# Cursor — Plugin system reference

Source of truth: <https://cursor.com/docs/plugins> and <https://cursor.com/docs/reference/plugins>.

A Cursor plugin is a Git repo that bundles **rules, skills, agents, commands, MCP servers, and/or hooks** into a single distributable. Browse official plugins at <https://cursor.com/marketplace>; community ones at <https://cursor.directory>. Plugins are manually reviewed before listing.

## Single vs multi-plugin layout

- **Single plugin** (what we use for Latitude): the plugin lives at the **repo root**. No `marketplace.json`.
- **Multi-plugin**: each plugin lives in its own subdirectory, plus a `.cursor-plugin/marketplace.json` at the repo root listing them all (max 500 plugins per marketplace).

## Single-plugin directory structure

```
my-plugin/
├── .cursor-plugin/
│   └── plugin.json        # Required: plugin manifest
├── rules/                 # Optional: .mdc files with YAML frontmatter
├── skills/                # Optional: <skill-name>/SKILL.md
├── agents/                # Optional: agent definitions
├── commands/              # Optional: agent-executable command files
├── hooks/hooks.json       # Optional: automation hooks
├── mcp.json               # Optional: MCP server definitions
├── assets/                # Logos / static assets
└── README.md
```

For Latitude we ship **only** `plugin.json`, `mcp.json`, `assets/`, and `README.md`.

## Manifest (`.cursor-plugin/plugin.json`)

Only `name` is required. Other useful fields:

| Field | Type | Notes |
| --- | --- | --- |
| `name` | string | Lowercase kebab-case. Alphanumerics, hyphens, periods. Must start/end alphanumeric. |
| `displayName` | string | Human-friendly name shown in the marketplace. |
| `description` | string | Short pitch. |
| `version` | string | Semver. |
| `author` | object | `name` (required), `email` (optional). |
| `homepage` | string | URL. |
| `repository` | string | URL. |
| `license` | string | SPDX id (e.g. `MIT`). |
| `keywords` | string[] | For discovery. |
| `logo` | string | Relative path inside the plugin (e.g. `assets/icon-light.png`) or absolute URL. Relative resolves to `raw.githubusercontent.com/<repo>/<sha>/<path>`. |
| `rules` / `skills` / `agents` / `commands` | string \| string[] | Override default folder discovery. |
| `hooks` | string \| object | Path or inline. |
| `mcpServers` | string \| object \| array | Overrides default `mcp.json` discovery. |

## MCP server config (`mcp.json`)

Auto-discovered when present at the plugin root. Schema:

```json
{
  "mcpServers": {
    "<name>": {
      "url": "https://..."   // remote streamable HTTP MCP (what we use)
    },
    "<other>": {
      "command": "npx",       // stdio MCP
      "args": ["-y", "..."],
      "env": { "FOO": "${FOO}" }
    }
  }
}
```

Cursor natively supports remote URL MCP servers with OAuth — the user is taken through the consent screen on first connect. No bridge needed.

## Logos

- Commit the logo to the repo and reference it via a **relative path** in the manifest.
- Absolute `https://raw.githubusercontent.com/...` URLs are accepted, but relative paths are preferred since they auto-resolve to the correct commit SHA.

## Local development

1. Symlink (or copy) the plugin folder into `~/.cursor/plugins/local/`:
   ```bash
   ln -s "$(pwd)/cursor" ~/.cursor/plugins/local/latitude
   ```
2. Restart Cursor or run **Developer: Reload Window**.
3. Verify under **Cursor Settings → Features → Model Context Protocol**.

To uninstall locally, delete the symlink and reload.

## Managing installed MCP servers

Toggle on/off at **Cursor Settings → Features → Model Context Protocol**. Disabled servers don't load.

## Submission

1. Push the plugin to a **public Git repo**.
2. Submit at <https://cursor.com/marketplace/publish>.
3. Wait for the Cursor team's review (every update is reviewed too).

### Submission checklist
- Valid `.cursor-plugin/plugin.json`.
- `name` is unique, lowercase, kebab-case.
- `description` clearly explains the plugin.
- All rule / skill / agent / command files (if any) have proper frontmatter.
- Logo committed and referenced by relative path.
- `README.md` documents usage.
- All paths in the manifest are relative and valid — no `..`, no absolute paths.
- Plugin has been tested locally.

## Team marketplaces

On Teams (1 marketplace) and Enterprise (unlimited) plans, admins can import private GitHub repos as team marketplaces under **Dashboard → Settings → Plugins**. Plugins can be marked **Required** (auto-installed for everyone in the distribution group) or **Optional**. SCIM groups can drive distribution. Not relevant for the Latitude plugin (we want to publish into the public marketplace).
