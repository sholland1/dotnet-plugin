local pickers = require("telescope.pickers")
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

local function get_projects()
  local project_paths = vim.fn.glob(vim.fn.getcwd() .. "/**/*.[fc]sproj", false, true)
  local relative_paths = {}
  for _, path in ipairs(project_paths) do
    table.insert(relative_paths, vim.fn.fnamemodify(path, ":~:."))
  end
  return relative_paths
end

local function pick_reference_to_remove(selection, opts)
  opts = opts or {}

  local list_reference_command = string.format(
    "dotnet list %s reference | tail -n +3 | sed 's/\\\\/\\//g'",
    selection[1])

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

  pickers.new(opts,{
    prompt_title = "Choose references to remove",

    finder = finders.new_table({
      results = references,
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local multi = picker:get_multi_selection()
        if vim.tbl_isempty(multi) then
          multi = { action_state.get_selected_entry() }
        end

        actions.close(prompt_bufnr)

        local commands = {}
        table.insert(commands, "pushd " .. vim.fn.fnamemodify(selection[1], ":h"))
        for _, entry in pairs(multi) do
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

local function pick_project(opts, continuation)
  opts = opts or {}

  pickers.new(opts,{
    prompt_title = "Choose a project",

    finder = finders.new_table({
      results = get_projects(),
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection == nil then
          return
        end
        continuation(selection, opts)
      end)
      return true
    end,
  }):find()
end

pick_project(require("telescope.themes").get_ivy(), pick_reference_to_remove)
