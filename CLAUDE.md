# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**notelink.nvim** is a lightweight Neovim plugin for managing markdown notes in a flat directory structure. It provides two commands:

- **`:LinkToNote`** — uses telescope to select and link to an existing markdown file
- **`:NewLinkedNote`** — creates a timestamped markdown file, links to it, and opens it in a new tab

This is a pure Lua plugin with no external build process or testing framework.

## Repository Structure

```
.
├── plugin/
│   └── notelink.lua          # Command registration (entry point)
├── lua/notelink/
│   └── init.lua              # Core implementation
├── README.md                 # User-facing documentation
├── LICENSE                   # MIT license
└── .gitignore
```

## Key Architecture

**Standard Neovim plugin structure:**
- `plugin/notelink.lua` registers the two user commands via `nvim_create_user_command()`
- `lua/notelink/init.lua` contains all implementation; exports a module `M` with `setup()`, `link_to_note()`, and `new_linked_note()` functions
- Configuration is stored in `M.config` and can be customized via `setup()` with sensible defaults

**Core concepts:**
- **File scanning:** Uses `vim.uv.fs_scandir()` (fallback to `vim.loop` in older Neovim) to find `.md` files in the current directory (non-recursive)
- **Link format:** Bare markdown syntax `[title](./filename.md)` inserted at cursor
- **Telescope integration:** For `:LinkToNote`, spawns a telescope picker to select from available markdown files
- **Heading detection:** Reads the first `# H1` from a markdown file as the link title; falls back to a prettified filename if none exists
- **Timestamped filenames:** `:NewLinkedNote` prefixes new files with a timestamp (default `YYYYMMDDHHMM`) to avoid collisions

## Development

**No build step required.** The plugin is written in pure Lua and runs directly in Neovim.

### Testing Changes

1. **In Neovim:** Install the plugin locally (e.g., via lazy.nvim in your config), or load the repo as `~/.config/nvim/plugins/linknote` and source it with `:luafile lua/notelink/init.lua`
2. **Test both commands:** Create a test directory with a few `.md` files and verify both `:LinkToNote` and `:NewLinkedNote` work correctly
3. **Verify configuration:** Test the `setup()` function with custom `date_format` and `new_note_template` options

### Key Implementation Details

**`current_dir()`** — Returns the directory of the current buffer's file, or falls back to `vim.fn.getcwd()` for unnamed buffers. This is the root for all file operations.

**`markdown_files(dir)`** — Lists `.md` files in `dir` (non-recursive), handling both regular files and symlinks. Returns a sorted list.

**`prettify(name)`** — Strips the `.md` extension, removes a leading timestamp (e.g., `202607281230-`), and converts dashes to spaces. Used as a fallback link title.

**`read_title(path, fallback)`** — Safely reads up to 50 lines from a markdown file and returns the first `# H1` heading, or the fallback value.

**`insert_link(title, relpath)`** — Inserts a markdown link at the cursor using `nvim_put()` in character-wise mode.

**Telescope integration in `link_to_note()`** — Handles the case where telescope is not installed by notifying the user with an error message.

**Error handling in `new_linked_note()`** — Checks if a file already exists before writing, and surfaces write errors to the user via `vim.notify()`.

## Dependencies

- **Neovim 0.9+** — Uses the stable API; vim.uv is preferred but falls back to vim.loop for compatibility
- **telescope.nvim** — Required only for `:LinkToNote`; `:NewLinkedNote` works standalone

## Common Tasks

### Add a new option to configuration

1. Add the new option to `M.config` with a sensible default
2. Document it in the `setup()` function's comment
3. Use the option in the relevant command implementation (usually via `M.config.option_name`)
4. Update the README.md `## Configuration` section

### Modify the link format

Edit the `insert_link()` function to change the link syntax. Currently it generates bare markdown `[title](./path)`. Ensure it works with both `:LinkToNote` and `:NewLinkedNote`.

### Change default filename format

Modify the `date_format` default in `M.config` or update the timestamp generation logic in `new_linked_note()`. Remember that filenames must be valid on all filesystems and human-readable.

## Notes for Contributors

- Keep the plugin lightweight and focused on its two core commands
- All user-facing errors should go through `vim.notify()` with appropriate log levels
- File operations should gracefully handle errors (e.g., permission denied, file already exists)
- Test with different Neovim configurations, especially those without telescope.nvim
