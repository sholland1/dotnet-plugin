local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")

local function pick_reference_to_remove(opts)
  local shell_cmds = require("dotnet-plugin.shell_cmds")

  opts = opts or {}

  local result0 = vim.fn.system(shell_cmds.projects)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  if result0:match("^Could not find") then
    print("No projects found.")
    return
  end

  local references = {}
  for project in result0:gmatch("[^\r\n]+") do
    local result1 = vim.fn.system(shell_cmds.references(project))
    if vim.v.shell_error ~= 0 then
      print("Failed to execute shell command.")
      goto continue
    end

    if result1:match("^Could not find") then
      print("No references found.")
      goto continue
    end

    for line in result1:gmatch("[^\r\n]+") do
      local reference = line:match("^%s*(.-)%s*$")
      table.insert(references, {
        project = project,
        reference = reference,
      })
    end

    ::continue::
  end

  if not references or #references == 0 then
    print("No references found.")
    return
  end

  -- Calculate max widths for each property
  local max_widths = {
    project = 0,
    reference = 0,
  }
  for _, entry in ipairs(references) do
    max_widths.project = math.max(max_widths.project, #entry.project)
    max_widths.reference = math.max(max_widths.reference, #entry.reference)
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = max_widths.project },
      { width = max_widths.reference },
    },
  })

  pickers.new(opts, {
    prompt_title = "Choose references to remove",

    finder = finders.new_table({
      results = references,
      entry_maker = function(entry)
        return {
          value = entry,
          display = function (ntry)
            return displayer({
              ntry.value.project,
              ntry.value.reference,
            })
          end,
          ordinal = entry.project .. '|' .. entry.reference,
        }
      end,
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
        for _, entry in pairs(selections) do
          table.insert(commands, shell_cmds.remove_reference(entry.value.project, entry.value.reference))
        end
        table.insert(commands, shell_cmds.restore)

        utils.execute_commands(commands)
      end)
      return true
    end,
  }):find()
end

return pick_reference_to_remove

