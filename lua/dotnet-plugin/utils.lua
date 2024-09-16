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
  local separator = vim.fn.has('win32') and "; " or " && "
  local multi_command = table.concat(commands, separator)
  vim.cmd("!" .. multi_command)
end

local function execute_in_term(commands)
  open_bottom_term()

  local separator = vim.fn.has('win32') and "; " or " && "
  local shell_command = vim.fn.has('win32') and "powershell.exe" or "sh"
  local multi_command = table.concat(commands, separator)
  local full_command = string.format('%s -c "%s"', shell_command, multi_command)
  vim.fn.termopen(full_command)

  vim.cmd('normal G$')
end

local function format_number(num)
  local formatted = tostring(num)
  local k = #formatted % 3
  if k == 0 then k = 3 end
  return formatted:sub(1, k) .. formatted:sub(k+1):gsub("(...)", ",%1")
end

return {
  exec_on_cmd_line = exec_on_cmd_line,
  execute_in_term = execute_in_term,
  format_number = format_number,
}
