if vim.g.loaded_notelink then
  return
end
vim.g.loaded_notelink = true

vim.api.nvim_create_user_command("LinkToNote", function()
  require("notelink").link_to_note()
end, {
  desc = "Link to a markdown note in the current directory and open it in a new tab",
})

vim.api.nvim_create_user_command("NewLinkedNote", function(opts)
  local title = opts.args

  -- If no args provided but a visual selection exists, use selected text as title
  if title == "" and opts.line1 and opts.line2 then
    local lines = vim.fn.getline(opts.line1, opts.line2)
    if lines and #lines > 0 then
      title = table.concat(lines, " ")
      -- Delete the selected text so the link replaces it
      vim.api.nvim_buf_set_text(0, opts.line1 - 1, 0, opts.line2, 0, {})
    end
  end

  require("notelink").new_linked_note(title)
end, {
  nargs = "*",
  range = true,
  desc = "Create a new timestamped markdown note, link to it, and open it in a new tab",
})

vim.api.nvim_create_user_command("NewNote", function(opts)
  require("notelink").new_note(opts.args)
end, {
  nargs = "+",
  desc = "Create a new timestamped markdown note and open it in a new tab",
})
