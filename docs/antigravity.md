# Antigravity — Plugin system reference

Source of truth: <https://antigravity.google/docs/plugins> and <https://antigravity.google/docs/mcp>.

A Google Antigravity plugin is a namespaced bundle that can group **skills, rules, MCP servers, and hooks** into a single deployable unit. Antigravity comes with bundled plugins ("Build with Google"); custom plugins are dropped into well-known directories and auto-discovered.

## Plugin directory structure

```
plugins/<plugin-name>/
├── plugin.json         # Required marker file
├── mcp_config.json     # Optional MCP server definitions
├── hooks.json          # Optional hooks definition
├── skills/             # Optional
│   └── <skill-name>/
│       └── SKILL.md
└── rules/              # Optional
    └── <rule-name>.md
```

For Latitude we ship **only** `plugin.json`, `mcp_config.json`, `assets/`, and `README.md`.

## Manifest (`plugin.json`)

Minimal — the only required job is to mark the directory as a plugin.

```json
{
  "name": "my-custom-plugin"
}
```

`name` is optional and defaults to the directory name. We set it explicitly to `latitude` for clarity.

## MCP server config (`mcp_config.json`)

```json
{
  "mcpServers": {
    "<name>": {
      "serverUrl": "https://api.example.com/mcp/"
    },
    "<stdio-example>": {
      "command": "path/to/executable",
      "args": ["--arg1", "value1"],
      "env": { "API_KEY": "..." },
      "cwd": "..."
    }
  }
}
```

### Required (one of)
- `command` — stdio transport.
- `serverUrl` — remote streamable HTTP transport.

### Optional
- `args`, `env`, `cwd` (stdio).
- `headers` — custom HTTP headers (remote).
- `authProviderType` — set to `"google_credentials"` to use Google ADC (`gcloud auth application-default login`).
- `oauth` — `{ clientId, clientSecret }` for OAuth servers **without** DCR. If you provide these, register `https://antigravity.google/oauth-callback` as a redirect URI in your OAuth provider.
- `disabled` — boolean.
- `disabledTools` — `string[]` of tool names to hide from the model.

### OAuth + Dynamic Client Registration (what Latitude uses)

> Antigravity can automatically handle OAuth for servers that support dynamic client registration (DCR). For these servers, no additional configuration is needed.

So `{ "serverUrl": "..." }` is literally enough. On first connect:

1. **Agent Settings → Customizations** → **Authenticate** next to the server.
2. Browser opens, user signs in, copies the auth code back into the panel.
3. Tokens are cached in `~/.gemini/antigravity/mcp_oauth_tokens.json` and auto-refreshed.

## Plugin install locations

Antigravity scans these directories on startup:

| Scope | Path |
| --- | --- |
| Workspace | `<workspace>/.agents/plugins/` or `<workspace>/_agents/plugins/` |
| User-global (Antigravity editor) | `~/.gemini/config/plugins/` |
| User-global (Antigravity CLI) | `~/.gemini/antigravity-cli/plugins/` |

Dropping a plugin folder into any of these makes it discoverable on next launch.

The CLI also tracks installed plugins via `~/.gemini/antigravity-cli/import_manifest.json`.

## Raw MCP config (no plugin)

For users who don't want a plugin wrapper, MCP servers can be added directly via the **MCP Store → Manage MCP Servers → View raw config**. That config file lives at `~/.gemini/antigravity/mcp_config.json` and uses the same `mcpServers` schema.

## Discovery & UI

- **MCP Store**: in the "..." dropdown at the top of the agent panel. Lists supported servers and lets users install / authenticate.
- **Customizations tab**: in Agent Settings (`Cmd+,` / `Ctrl+,`). Lists installed plugins; per-server Authenticate buttons live here.

## Submission

The Antigravity docs describe two install paths:

1. **Bundled plugins (Build with Google)** — first-party, curated by Google. No public self-serve submission process documented as of writing.
2. **Manually adding plugins** — users drop folders into one of the install locations above. This is the primary path for third-party publishers today.

Until Google opens a public submission flow, the best distribution channel is hosting the plugin on a public Git repo and giving users a one-liner copy instruction.
