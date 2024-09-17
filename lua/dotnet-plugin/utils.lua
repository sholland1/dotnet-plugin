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
  local separator = vim.fn.has('win32') == 1 and "; " or " && "
  local multi_command = table.concat(commands, separator)
  vim.cmd("!" .. multi_command)
end

local function execute_in_term(commands)
  open_bottom_term()

  local separator = vim.fn.has('win32') == 1 and "; " or " && "
  local shell_command = vim.fn.has('win32') == 1 and "powershell.exe" or "sh"
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

local function split_into_columns(str)
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

return {
  exec_on_cmd_line = exec_on_cmd_line,
  execute_in_term = execute_in_term,
  format_number = format_number,
  split_into_columns = split_into_columns,
}
