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

return {
  exec_on_cmd_line = exec_on_cmd_line,
  execute_in_term = execute_in_term,
  get_projects = get_projects,
}
