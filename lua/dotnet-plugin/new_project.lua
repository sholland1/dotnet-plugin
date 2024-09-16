local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local execute_commands  = require("dotnet-plugin.utils").exec_on_cmd_line

local function splitIntoColumns(str)
  local columns = {}
  local START, IN_WORD, IN_WORD2, BREAK = 0, 1, 2, 3
  local state = START
  local first_index = 0
  for i = 1, #str - 1 do
    local c = string.sub(str, i, i)
    if state == START then
      if c == ' ' then
        state = BREAK
      else
        state = IN_WORD
        first_index = i
      end
    elseif state == IN_WORD then
      if c == ' ' then
        state = IN_WORD2
      end
    elseif state == IN_WORD2 then
      if c == ' ' then
        state = BREAK
        table.insert(columns, string.sub(str, first_index, i-2))
      else
        state = IN_WORD
      end
    elseif state == BREAK then
      if c ~= ' ' then
        state = IN_WORD
        first_index = i
      end
    end
  end

  local c = string.sub(str, #str, #str)
  local i = #str

  if state == IN_WORD then
    if c == ' ' then
      table.insert(columns, string.sub(str, first_index, i-1))
    else
      table.insert(columns, string.sub(str, first_index, i))
    end
  elseif state == IN_WORD2 then
    if c == ' ' then
      table.insert(columns, string.sub(str, first_index, i-2))
    else
      table.insert(columns, string.sub(str, first_index, i-1))
    end
  elseif state == BREAK then
    if c ~= ' ' then
      table.insert(columns, string.sub(str, i, i))
    end
  end

  return columns
end

local function pick_projects(opts, continuation)
  opts = opts or {}

  local job_command = vim.fn.has('win32') and
    {"powershell.exe", "-c", "dotnet new list --type=project | Select-Object -Skip 4"} or
    {"sh", "-c", "dotnet new list --type=project | tail -n +5"}

  pickers.new(opts, {
    prompt_title = "New Project",

    finder = finders.new_oneshot_job(job_command, {
      entry_maker = function(entry)
        local columns = {}
        for _, col in pairs(splitIntoColumns(entry)) do
          table.insert(columns, col)
        end
        local new_entry = {
          template_name = columns[1],
          short_name = columns[2],
          language = columns[3],
          tags = columns[4],
        }
        return {
          value = new_entry,
          display = entry,
          ordinal = new_entry.template_name,
        }
      end
    }),

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()

        actions.close(prompt_bufnr)

        continuation(opts, selection)
      end)
      return true
    end,
  }):find()
end

local function add_project(_, project)
  local project_name = vim.fn.input("Enter project name: ")
  if project_name == "" then
    vim.print("Project name cannot be empty.")
    return
  end

  local commands = {
    "dotnet new " .. project.value.short_name .. " -o " .. project_name,
    "dotnet sln add " .. project_name .. "/" .. project_name .. ".csproj",
  }
  execute_commands(commands)
end

return function(opts) pick_projects(opts, add_project) end

-- local strings = {
--   "   Hello   world  how are you   ",
--   "   Hello   world  how are you  ",
--   "   Hello   world  how are you ",
--   "   Hello   world  how are you",
--
--   "  Hello   world  how are you   ",
--   "  Hello   world  how are you  ",
--   "  Hello   world  how are you ",
--   "  Hello   world  how are you",
--
--   " Hello   world  how are you   ",
--   " Hello   world  how are you  ",
--   " Hello   world  how are you ",
--   " Hello   world  how are you",
--
--   "Hello   world  how are you   ",
--   "Hello   world  how are you  ",
--   "Hello   world  how are you ",
--   "Hello   world  how are you",
--
--   "a   ",
--   "a  ",
--   "a ",
--   "   a",
--   "  a",
--   " a",
--   "  a ",
--   " a ",
--   " a",
--   "   ",
--   "  ",
--   " ",
--   "",
-- }
--
-- for _, str in pairs(strings) do
--   vim.print(splitIntoColumns(str))
-- end
