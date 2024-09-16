local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")
local execute_commands = utils.exec_on_cmd_line

local pick_projects = require("dotnet-plugin.project_picker")

local function pick_reference_to_remove(opts, selection)
  opts = opts or {}

  local project = selection[1].value

  local list_reference_command = string.format(
    "dotnet list %s reference | tail -n +3 | sed 's/\\\\/\\//g'",
    project)

  local handle = io.popen(list_reference_command)
  if handle == nil then
    print("Failed to execute shell command.")
    return
  end

  local result = handle:read("*a")
  handle:close()

  if result:match("^Could not find") then
    print("No references found.")
    return
  end

  local references = {}
  for line in result:gmatch("[^\r\n]+") do
    local path = line:match("^%s*(.-)%s*$")
    table.insert(references, path)
  end

  if not references or #references == 0 then
    print("No references found.")
    return
  end

  pickers.new(opts, {
    prompt_title = "Choose references to remove",

    finder = finders.new_table({
      results = references,
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          selections = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        local commands = {}
        table.insert(commands, "pushd " .. vim.fn.fnamemodify(project, ":h"))
        for _, entry in pairs(selections) do
          table.insert(commands, "dotnet remove reference " .. entry.value)
        end
        table.insert(commands, "popd")
        table.insert(commands, "dotnet restore")

        execute_commands(commands)
      end)
      return true
    end,
  }):find()
end

return function (opts) pick_projects(opts, pick_reference_to_remove) end

