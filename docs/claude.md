# Claude Code — Plugin system reference

Source of truth: <https://code.claude.com/docs/en/plugins> and <https://code.claude.com/docs/en/plugins-reference>.

A Claude Code plugin packages **skills, agents, hooks, MCP servers, LSP servers, and background monitors** into a shareable bundle that's distributed through plugin marketplaces. Anthropic operates two public marketplaces:

- **`claude-plugins-official`** — curated by Anthropic, available automatically in every Claude Code install.
- **`claude-community`** — third-party submissions; users add via `/plugin marketplace add anthropics/claude-plugins-community`, install as `@claude-community/<name>`.

## Standalone config vs plugins

Claude Code supports two ways to add skills / agents / hooks:

| Approach | Skill names | Best for |
| --- | --- | --- |
| **Standalone** (`.claude/` in a repo) | `/hello` | Personal workflows, project-specific tweaks, quick experiments. |
| **Plugins** | `/plugin-name:hello` | Sharing across teams / community, versioned, reusable. |

For Latitude we ship a plugin.

## Plugin directory structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json     # Required: manifest (only file inside .claude-plugin)
├── skills/             # Optional: <name>/SKILL.md folders
├── commands/           # Optional: flat .md skill files (legacy — use skills/ for new plugins)
├── agents/             # Optional: agent definitions
├── hooks/hooks.json    # Optional: event handlers
├── .mcp.json           # Optional: MCP server configs (note: leading dot)
├── .lsp.json           # Optional: LSP server configs
├── monitors/           # Optional: background monitor configs
├── bin/                # Optional: executables added to Bash PATH while plugin is enabled
└── settings.json       # Optional: default settings applied when plugin is enabled
```

**Common mistake**: never put `commands/`, `agents/`, `skills/`, or `hooks/` **inside** `.claude-plugin/`. Only `plugin.json` lives there. Everything else lives at the plugin root.

For Latitude we ship **only** `plugin.json`, `.mcp.json`, `assets/`, and `README.md`.

## Manifest (`.claude-plugin/plugin.json`)

```json
{
  "name": "my-plugin",
  "description": "What the plugin does",
  "version": "1.0.0",
  "author": { "name": "Your Name" },
  "homepage": "https://...",
  "repository": "https://...",
  "license": "MIT",
  "keywords": ["..."]
}
```

`name` is required and namespaces the plugin's skills (e.g. `/my-plugin:hello`). For full schema: <https://code.claude.com/docs/en/plugins-reference>.

### Version management
- Explicit `version` → users only get updates when you bump it.
- Omit `version` and distribute via git → commit SHA is the version, every commit ships as new.

## MCP server config (`.mcp.json`)

```json
{
  "mcpServers": {
    "<name>": {
      "type": "http",
      "url": "https://api.example.com/mcp"
    },
    "<stdio-example>": {
      "command": "npx",
      "args": ["-y", "package"],
      "env": { "API_KEY": "${API_KEY}" }
    }
  }
}
```

Claude Code supports remote streamable HTTP MCP with OAuth + Dynamic Client Registration, so `{ "type": "http", "url": "..." }` is enough for Latitude. The CLI also exposes `claude mcp add --transport http <name> <url> --scope user` for manual config edits.

> ⚠️ **Claude Code ≠ Claude Desktop.** Latitude's manual-install docs recommend `mcp-remote` for the Claude Desktop chat app because that app doesn't yet support remote OAuth MCP natively. Plugins target Claude **Code** (the coding agent), which does support it — so no bridge is needed.

## Local development

```bash
claude --plugin-dir ./my-plugin
# or load a packaged archive (Claude Code 2.1.128+)
claude --plugin-dir ./my-plugin.zip
# or from a URL
claude --plugin-url https://example.com/my-plugin.zip
```

Multiple `--plugin-dir` / `--plugin-url` flags load multiple plugins.

When a `--plugin-dir` plugin shares a name with an installed one, the local copy wins for that session (handy for testing changes without uninstalling).

While iterating: `/reload-plugins` picks up changes without restarting.

## Validation

Run before submission:

```bash
claude plugin validate ./my-plugin
```

The community-marketplace review pipeline runs the same check.

## Submission

Use the in-app submission flow:

- Claude.ai: <https://claude.ai/settings/plugins/submit>
- Console: <https://platform.claude.com/plugins/submit>

Approved plugins are pinned to a specific commit SHA in [`anthropics/claude-plugins-community`](https://github.com/anthropics/claude-plugins-community). CI bumps the pin automatically as you push new commits. The public catalog syncs **nightly**, so expect a delay between approval and the plugin appearing in `marketplace.json`.

The official marketplace (`claude-plugins-official`) is curated separately at Anthropic's discretion — there's no application process, and the submission form does not add to it.

## Migrating from `.claude/` standalone configs

Existing skills / hooks in `.claude/commands/`, `.claude/agents/`, `.claude/skills/`, and `~/.claude/settings.json` can be moved into a plugin directory and registered via `plugin.json`. Hooks move from `settings.json` → `hooks/hooks.json` (same schema).
