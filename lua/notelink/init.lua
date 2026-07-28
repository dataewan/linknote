local M = {}

local uv = vim.uv or vim.loop

M.config = {
  -- Timestamp prepended to new note filenames. Default: YYYYMMDDHHMM.
  date_format = "%Y%m%d%H%M",
  -- Contents a new note is seeded with. `title` is the words you passed to
  -- :NewLinkedNote. Return a list of lines.
  new_note_template = function(title)
    return { "# " .. title, "" }
  end,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- Directory of the current buffer's file, falling back to the cwd for
-- unnamed buffers.
local function current_dir()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  return dir
end

-- Markdown files directly inside `dir` (non-recursive), sorted by name.
local function markdown_files(dir)
  local files = {}
  local handle = uv.fs_scandir(dir)
  if handle then
    while true do
      local name, typ = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if (typ == "file" or typ == "link") and name:match("%.md$") then
        table.insert(files, name)
      end
    end
  end
  table.sort(files)
  return files
end

-- Prettify a filename for use as a link title when no heading is found:
-- strip a leading timestamp and the extension, turn dashes into spaces.
local function prettify(name)
  local base = name:gsub("%.md$", "")
  base = base:gsub("^%d+%-", "")
  base = base:gsub("%-", " ")
  return base
end

-- Title of a note: its first `# H1`, or a prettified filename as fallback.
local function read_title(path, fallback)
  local ok, lines = pcall(vim.fn.readfile, path, "", 50)
  if ok then
    for _, line in ipairs(lines) do
      local h1 = line:match("^#%s+(.+)")
      if h1 then
        return vim.trim(h1)
      end
    end
  end
  return fallback
end

-- Insert a bare markdown link at the cursor.
local function insert_link(title, relpath)
  local link = string.format("[%s](%s)", title, relpath)
  vim.api.nvim_put({ link }, "c", true, true)
end

local function open_in_tab(path)
  vim.cmd("tabedit " .. vim.fn.fnameescape(path))
end

-- :LinkToNote — pick a markdown file from the current directory, insert a
-- link to it at the cursor, and open it in a new tab.
function M.link_to_note()
  local dir = current_dir()
  local files = markdown_files(dir)
  if vim.tbl_isempty(files) then
    vim.notify("notelink: no markdown files in " .. dir, vim.log.levels.WARN)
    return
  end

  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("notelink: telescope.nvim is required for :LinkToNote", vim.log.levels.ERROR)
    return
  end
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = "Link to Note",
      finder = finders.new_table({ results = files }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if not entry then
            return
          end
          local name = entry[1]
          local fullpath = dir .. "/" .. name
          local title = read_title(fullpath, prettify(name))
          insert_link(title, "./" .. name)
          open_in_tab(fullpath)
        end)
        return true
      end,
    })
    :find()
end

-- :NewLinkedNote {words} — create a timestamped markdown note in the current
-- directory named after {words}, insert a link to it at the cursor, and open
-- it in a new tab.
function M.new_linked_note(title)
  title = vim.trim(title or "")
  if title == "" then
    vim.notify("notelink: :NewLinkedNote requires a title", vim.log.levels.ERROR)
    return
  end

  local slug = title:gsub("%s+", "-")
  local timestamp = os.date(M.config.date_format)
  local filename = string.format("%s-%s.md", timestamp, slug)
  local dir = current_dir()
  local fullpath = dir .. "/" .. filename

  if uv.fs_stat(fullpath) then
    vim.notify("notelink: file already exists: " .. filename, vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(vim.fn.writefile, M.config.new_note_template(title), fullpath)
  if not ok then
    vim.notify("notelink: failed to write " .. filename .. ": " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  insert_link(title, "./" .. filename)
  open_in_tab(fullpath)
end

return M
