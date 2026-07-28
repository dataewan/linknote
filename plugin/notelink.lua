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
  require("notelink").new_linked_note(opts.args)
end, {
  nargs = "+",
  desc = "Create a new timestamped markdown note, link to it, and open it in a new tab",
})
