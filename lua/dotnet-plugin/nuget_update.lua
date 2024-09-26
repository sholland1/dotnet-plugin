local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local utils = require("dotnet-plugin.utils")

local update_package = function(opts)
  local shell_cmds = require("dotnet-plugin.shell_cmds")
  opts = opts or {}

  local result = vim.fn.system(shell_cmds.outdated_packages)
  if vim.v.shell_error ~= 0 then
    print("Failed to execute shell command.")
    return
  end

  local json = vim.json.decode(result)
  local results = {}
  for _, project in ipairs(json.projects or {}) do
    local filename = vim.fn.fnamemodify(project.path, ":t")
    for _, framework in ipairs(project.frameworks or {}) do
      for _, pkg in ipairs(framework.topLevelPackages or {}) do
        table.insert(results, {
          filename = filename,
          id = pkg.id,
          resolvedVersion = pkg.resolvedVersion,
          latestVersion = pkg.latestVersion,
          projectPath = string.format("'%s'", project.path),
        })
      end
    end
  end

  if not results or #results == 0 then
    print("No outdated packages found.")
    return
  end

  -- Calculate max widths for each property
  local max_widths = {
    filename = 0,
    id = 0,
    resolvedVersion = 0,
    latestVersion = 0
  }
  for _, entry in ipairs(results) do
    max_widths.filename = math.max(max_widths.filename, #entry.filename)
    max_widths.id = math.max(max_widths.id, #entry.id)
    max_widths.resolvedVersion = math.max(max_widths.resolvedVersion, #entry.resolvedVersion)
    max_widths.latestVersion = math.max(max_widths.latestVersion, #entry.latestVersion)
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = max_widths.filename },
      { width = max_widths.id },
      { width = max_widths.resolvedVersion },
      { width = max_widths.latestVersion },
    },
  })

  pickers.new(opts, {
    prompt_title = "Select outdated packages to update",

    finder = finders.new_table({
      results = results,
      entry_maker = function (entry)
        return {
          value = entry,
          display = function (ntry)
            return displayer({
              ntry.value.filename,
              ntry.value.id,
              ntry.value.resolvedVersion,
              ntry.value.latestVersion,
            })
          end,
          ordinal = entry.filename .. '|' .. entry.id,
        }
      end
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function (prompt_bufnr, _)
      actions.select_default:replace(function ()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          selections = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        local commands = {}
        for _, entry in pairs(selections) do
          local update_command = shell_cmds.update_package(
            entry.value.projectPath,
            entry.value.id,
            entry.value.latestVersion)
          table.insert(commands, update_command)
        end

        utils.execute_commands(commands)
      end)
      return true
    end,
  }):find()
end

return update_package

