# notelink.nvim

A tiny Neovim plugin for linking markdown notes together. It gives you two
commands for working with a flat directory of markdown notes:

- **`:LinkToNote`** — pick an existing markdown file from the current
  directory with [telescope](https://github.com/nvim-telescope/telescope.nvim),
  insert a link to it at the cursor, and open it in a new tab.
- **`:NewLinkedNote {words}`** — create a new timestamped markdown note named
  after `{words}`, insert a link to it at the cursor, and open it in a new tab.

Links are inserted as bare markdown: `[title](./the-note.md)`.

## Requirements

- Neovim 0.9+
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (for `:LinkToNote`)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "dataewan/linknote",
  dependencies = { "nvim-telescope/telescope.nvim" },
  cmd = { "LinkToNote", "NewLinkedNote" },
  -- opts = {}, -- optional, see Configuration
}
```

Calling `setup()` is optional — the commands are registered on load. Only call
it if you want to override defaults.

## Usage

### `:LinkToNote`

Run it anywhere in a markdown file. A telescope picker lists every `.md` file
in the current file's directory (non-recursive). Select one and a link is
inserted at the cursor, then the note opens in a new tab.

The link title is taken from the note's first `# heading`. If it has none, a
prettified version of the filename is used (leading timestamp stripped, dashes
turned into spaces).

### `:NewLinkedNote {words}`

```
:NewLinkedNote my great idea
```

Creates `202607281230-my-great-idea.md` in the current file's directory:
spaces in `{words}` become `-`, and the filename is prefixed with the current
timestamp (`YYYYMMDDHHMM` by default) to avoid collisions. A link
`[my great idea](./202607281230-my-great-idea.md)` is inserted at the cursor,
the file is seeded with `# my great idea`, and it opens in a new tab.

## Configuration

Defaults:

```lua
require("notelink").setup({
  -- Timestamp prepended to new note filenames (Lua os.date format).
  date_format = "%Y%m%d%H%M",

  -- Lines a new note is seeded with. `title` is the words you passed.
  new_note_template = function(title)
    return { "# " .. title, "" }
  end,
})
```

## License

MIT
