## Overview

A small Neovim plugin for linking a flat directory of markdown notes. It exposes three user commands:

- `:LinkToNote` — pick an existing note (telescope), insert a bare markdown link (`[title](./note.md)`) at the cursor, open it in a new tab.
- `:NewLinkedNote {words}` — create a timestamped note, insert a link to it at the cursor, open it in a new tab.
- `:NewNote {words}` — create a timestamped note and open it in a new tab, without inserting a link.

See `README.md` for user-facing behavior and configuration.

## Naming caveat

The git repo/directory is `linknote`, but the Lua module and runtime name are **`notelink`**. Requiring, config, and file paths all use `notelink` (`require("notelink")`, `lua/notelink/init.lua`, `vim.g.loaded_notelink`). Don't "fix" one to match the other without confirming — the README's install snippet points lazy.nvim at the `dataewan/linknote` repo but loads the `notelink` module.

## Architecture

Two files, following the standard Neovim plugin split:

- `plugin/notelink.lua` — loaded automatically by Neovim. Guards against double-load via `vim.g.loaded_notelink` and registers the three `nvim_create_user_command`s, each of which lazily `require("notelink")`. Calling `setup()` is optional; commands work without it.
- `lua/notelink/init.lua` — all logic. `M.config` holds defaults (`date_format`, `new_note_template`); `M.setup(opts)` deep-merges overrides. Key internals: `current_dir()` (buffer's dir, falling back to cwd), `markdown_files()` (non-recursive `uv.fs_scandir`), `read_title()` (first `# H1`, else `prettify()`d filename), `insert_link()` (via `nvim_put`), `open_in_tab()`, and `create_note(title, cmd_name)` — the shared trim/slug/timestamp/exists-check/write step behind both `M.new_linked_note` and `M.new_note`, returning `(fullpath, filename, title)` or `nil` after notifying.

Uses `vim.uv or vim.loop` for filesystem access. `:LinkToNote` requires telescope.nvim and degrades gracefully (`pcall(require, "telescope.pickers")`) with a notification if absent; `:NewLinkedNote` and `:NewNote` have no external dependency.

## Development

There is no build, lint, or test setup — it's a pure-Lua plugin with no tooling config. To test changes, load the plugin in a real Neovim session (e.g. point a plugin manager at the local checkout, or `:set runtimepath+=.`) and exercise the commands in a markdown buffer.
