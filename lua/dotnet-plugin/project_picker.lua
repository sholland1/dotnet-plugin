local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function get_projects()
  local sln_files = vim.fn.glob(vim.fn.getcwd() .. "/**/*.sln", false, true)
  if #sln_files == 0 then
    print("No .sln file found in the current directory or its subdirectories.")
    return {}
  end

  local sln_file = sln_files[1]
  local handle = io.open(sln_file, "r")
  if not handle then
    print("Failed to open .sln file.")
    return {}
  end

  local relative_paths = {}
  for line in handle:lines() do
    local project_path = line:match('Project%([^)]+%)%s*=%s*"[^"]*"%s*,%s*"([^"]*)"')
    if project_path then
      local full_path = vim.fn.fnamemodify(sln_file, ":h") .. "/" .. project_path
      table.insert(relative_paths, vim.fn.fnamemodify(full_path, ":~:."))
    end
  end
  handle:close()

  return relative_paths
end

local function pick_projects(opts, continuation)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "Projects",

    finder = finders.new_table({
      results = get_projects(),
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

        continuation(opts, selections)
      end)
      return true
    end,
  }):find()
end

return pick_projects
