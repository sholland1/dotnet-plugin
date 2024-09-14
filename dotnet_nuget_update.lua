local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function open_bottom_term(height)
  -- Calculate the height of the terminal window
  local term_height = height or math.floor(vim.o.lines * 0.3)

  -- Open a new window at the bottom
  vim.cmd('botright ' .. term_height .. 'split')

  -- Get the window and buffer numbers
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set the buffer in the window
  vim.api.nvim_win_set_buf(win, buf)

  return buf, win
end

local function exec_on_cmd_line(commands)
  local bash_command = table.concat(commands, " && ")
  vim.cmd("!"..bash_command)
end

local function execute_in_term(commands)
  open_bottom_term()

  local bash_command = table.concat(commands, " && ")
  local full_command = string.format('bash -c "%s"', bash_command)
  vim.fn.termopen(full_command)

  vim.cmd('normal G$')
end

local function execute_commands(commands)
  exec_on_cmd_line(commands)
end

local dotnet_nuget = function(opts)
  opts = opts or {}

  local outdated_packages_command = 'dotnet list package --outdated --format=json'

  local handle = io.popen(outdated_packages_command)
  if handle == nil then
    print("Failed to execute shell command.")
    return
  end

  local result = handle:read("*a")
  handle:close()

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
          projectPath = project.path,
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
        local multi = picker:get_multi_selection()
        if vim.tbl_isempty(multi) then
          multi = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        local commands = {}
        for _, entry in pairs(multi) do
          local update_command = string.format(
            "dotnet add %s package %s --version %s",
            entry.value.projectPath,
            entry.value.id,
            entry.value.latestVersion)
          table.insert(commands, update_command)
        end

        execute_commands(commands)
      end)
      return true
    end,
  }):find()
end

dotnet_nuget(require("telescope.themes").get_ivy())
