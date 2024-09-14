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

return {
  exec_on_cmd_line = exec_on_cmd_line,
  execute_in_term = execute_in_term,
}
