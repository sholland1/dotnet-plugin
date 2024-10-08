local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local pick_projects = require("dotnet-plugin.project_picker")
local utils  = require("dotnet-plugin.utils")

local function pick_reference_to_add(opts, selection)
  local shell_cmds = require("dotnet-plugin.shell_cmds")

  opts = opts or {}

  local project = selection[1].value

  local existing_references = vim.fn.system(shell_cmds.existing_references(project))
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local existing_projects = vim.fn.system(shell_cmds.existing_projects)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local existing_references_set = {}
  for reference in existing_references:gmatch("[^\r\n]+") do
    reference = vim.fn.fnamemodify(reference, ":p")
    existing_references_set[reference] = true
  end
  local temp = vim.fn.fnamemodify(project, ":p")
  existing_references_set[temp] = true

  local unreferenced_projects = {}
  for proj in existing_projects:gmatch("[^\r\n]+") do
    if not existing_references_set[vim.fn.fnamemodify(proj, ":p")] then
      table.insert(unreferenced_projects, proj)
    end
  end

  if not unreferenced_projects or #unreferenced_projects == 0 then
    print("No unreferenced projects found.")
    return
  end

  pickers.new(opts, {
    prompt_title = "Unreferenced Projects",

    finder = finders.new_table({
      results = unreferenced_projects,
    }),

    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          selections = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        local commands = {}
        for _, entry in pairs(selections) do
          table.insert(commands, shell_cmds.add_reference(project, entry.value))
        end
        table.insert(commands, shell_cmds.restore)

        utils.execute_commands(commands)
      end)
      return true
    end,
  }):find()
end

return function (opts) pick_projects(opts, pick_reference_to_add) end

