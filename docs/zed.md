# Zed — Extension system reference

Source of truth: <https://zed.dev/docs/extensions/mcp-extensions> and the [`zed_extension_api`](https://crates.io/crates/zed_extension_api) crate.

A Zed extension is a **Git repository** with an `extension.toml` manifest. Procedural parts are written in **Rust** and compiled to **WebAssembly** via `cargo build --target wasm32-wasip1`. Extensions can ship languages, themes, icon themes, snippets, debuggers, slash commands, and **MCP servers** (a.k.a. context servers).

## Prerequisite for dev work

Rust must be installed via [`rustup`](https://rustup.rs/). Homebrew Rust does **not** work for Zed dev extensions.

## Extension directory structure

Minimum:

```
my-extension/
├── extension.toml
├── Cargo.toml
├── LICENSE              # Required at extension root (or at the configured path)
└── src/lib.rs
```

A maximal extension can also include `languages/`, `themes/`, `snippets/`, `debug_adapters/`, `icon_themes/`, etc.

## `extension.toml`

```toml
id = "my-extension"
name = "My Extension"
version = "0.0.1"
schema_version = 1
authors = ["Your Name <you@example.com>"]
description = "Example extension"
repository = "https://github.com/your-name/my-zed-extension"

[context_servers.my-context-server]
# Bind a context server id to this extension.
# Rust code must implement context_server_command for this id.
```

Naming rules:
- `id` must **not** contain `zed`, `Zed`, or `extension`.
- IDs should hint at the purpose. Themes get `-theme`, snippet packs get `-snippets`, etc.

## `Cargo.toml`

```toml
[package]
name = "my-extension"
version = "0.0.1"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
zed_extension_api = "0.1.0"   # Use the latest compatible version on crates.io
```

`stdout`/`stderr` from the extension are forwarded to the Zed process. Launch Zed with `zed --foreground` to see `dbg!`/`println!` output.

## Rust entry point

```rust
use zed_extension_api as zed;

struct MyExtension;

impl zed::Extension for MyExtension {
    fn new() -> Self { Self }

    fn context_server_command(
        &mut self,
        _context_server_id: &zed::ContextServerId,
        _project: &zed::Project,
    ) -> zed::Result<zed::Command> {
        Ok(zed::Command {
            command: "my-server-binary".to_string(),
            args: vec![],
            env: vec![],
        })
    }
}

zed::register_extension!(MyExtension);
```

### Important constraint for MCP

The extension API only supports **spawn-based context servers** — `context_server_command` returns a `Command` (binary + args + env) that Zed runs on the host. There is **no extension-side API to register a remote URL** the way `~/.config/zed/settings.json` allows:

```json
{
  "context_servers": {
    "latitude": { "url": "https://api.latitude.so/v1/mcp" }
  }
}
```

So for a remote OAuth MCP, the extension has to bridge — typically via `npx mcp-remote <url>`, which requires Node.js on the user's machine.

If you need to download the MCP server from GitHub Releases / npm / etc., the docs recommend doing it inside `context_server_command` (or the relevant API on first use). Extensions must **not** ship server binaries themselves.

## License requirement

As of 2025-10-01, extension repositories **must** include one of these licenses:

- Apache 2.0
- BSD 2-Clause / BSD 3-Clause
- CC BY 4.0
- GNU GPLv3 / LGPLv3
- MIT
- Unlicense
- zlib

File name must start with `LICENCE` or `LICENSE` (case-insensitive). The license requirement covers extension code only — bundled tools (language servers, etc.) keep their own licenses.

## Local development

1. From Zed's **Extensions** page, click **Install Dev Extension** (or run the `zed: install dev extension` action).
2. Pick the extension folder. The published version, if any, is overridden during the dev session.
3. To debug: `zed --foreground` for verbose logs. `zed: open log` shows `Zed.log`.

## Submission

1. Fork [`zed-industries/extensions`](https://github.com/zed-industries/extensions). Forks to a **personal** account are easier for Zed staff to push fixes to than forks to org accounts.
2. Clone and run:
   ```bash
   git clone <your-fork>
   cd extensions
   git submodule init
   git submodule update
   ```
3. Add the extension as a Git submodule (must use **HTTPS**, public repo, on a **branch** — not a detached commit):
   ```bash
   git submodule add https://github.com/<you>/<repo>.git extensions/<id>
   git add extensions/<id>
   ```
   If the extension lives in a subdirectory of the submodule, also add `path = "subdir"` to the entry.
4. Add an entry to the top-level `extensions.toml`:
   ```toml
   [<id>]
   submodule = "extensions/<id>"
   version = "0.0.1"
   ```
   Version must match what's in the extension's `extension.toml` at that commit.
5. Run `pnpm sort-extensions` to keep `extensions.toml` and `.gitmodules` sorted.
6. Open the PR.

Once merged, Zed packages and publishes the extension to its registry.

### Prerequisites enforced at submission

- ID and name must not contain `zed` or `extension`.
- ID should hint at purpose (`-theme`, `-snippets`, etc., when applicable).
- Provides something not already in the marketplace (prefer contributing to an existing extension over forking).
- Does not ship a language server / MCP server binary — must download or use the host environment.
- Themes / icon themes are not bundled with feature extensions; ship separately.

## Updating

Open another PR:

1. Update the submodule to the new commit:
   ```bash
   git submodule update --remote extensions/<id>
   ```
2. Bump `version` in `extensions.toml` to match the new `extension.toml`.
3. If the repo's license changed, ensure it's still one of the accepted ones.

A community GitHub Action exists to automate the version-bump PR.
