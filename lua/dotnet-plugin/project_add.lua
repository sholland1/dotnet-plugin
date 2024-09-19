local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")

local function pick_missing_projects(opts, continuation)
  local shell_cmds = require("dotnet-plugin.shell_cmds")

  opts = opts or {}

  local existing_projects = vim.fn.system(shell_cmds.fixed_existing_projects)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local all_projects = vim.fn.system(shell_cmds.all_projects)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local existing_projects_set = {}
  for project in existing_projects:gmatch("[^\r\n]+") do
    existing_projects_set[project] = true
  end

  local missing_projects = {}
  for project in all_projects:gmatch("[^\r\n]+") do
    if not existing_projects_set[project] then
      table.insert(missing_projects, project)
    end
  end

  if not missing_projects or #missing_projects == 0 then
    print("No missing projects found.")
    return
  end

  pickers.new(opts, {
    prompt_title = "Projects not in Solution",

    finder = finders.new_table({
      results = missing_projects,
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

        continuation(opts, selections)
      end)
      return true
    end,
  }):find()
end

local function add_projects(_, projects)
  local shell_cmds = require("dotnet-plugin.shell_cmds")
  local commands = {}
  for _, entry in pairs(projects) do
    table.insert(commands, shell_cmds.add_project(entry.value))
  end
  utils.execute_commands(commands)
end

return function (opts) pick_missing_projects(opts, add_projects) end

