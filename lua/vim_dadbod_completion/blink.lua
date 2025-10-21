---@type blink.cmp.Source
local M = {}

local map_kind_to_cmp_lsp_kind = {
  F = 3,  -- Function -> Function
  C = 5,  -- Column -> Field
  A = 6,  -- Alias -> Variable
  T = 7,  -- Table -> Class
  V = 7,  -- View -> Class
  R = 14, -- Reserved -> Keyword
  P = 2,  -- Procedure -> Method
  D = 8,  -- Database -> Module
  S = 19, -- Schema -> Folder
}

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { '"', '`', '[', ']', '.' }
end

function M:enabled()
  local filetypes = { "sql", "mysql", "plsql" }
  return vim.tbl_contains(filetypes, vim.bo.filetype)
end

function M:get_completions(ctx, callback)
  local cursor_col = ctx.cursor[2]
  local line = ctx.line
  local word_start = cursor_col + 1

  local triggers = self:get_trigger_characters()
  while word_start > 1 do
    local char = line:sub(word_start - 1, word_start - 1)
    if vim.tbl_contains(triggers, char) or char:match('%s') then
      break
    end
    word_start = word_start - 1
  end

  -- Get text from word start to cursor
  local input = line:sub(word_start, cursor_col)

  if input ~= '' and input:match('[^0-9A-Za-z_]+') then
    input = ''
  end

  local transformed_callback = function(items)
    callback({
      context = ctx,
      is_incomplete_forward = true,
      is_incomplete_backward = true,
      items = items,
    })
  end

  -- Try enhanced vim-dadbod-ui IntelliSense first (if available)
  local bufnr = vim.api.nvim_get_current_buf()
  local results = {}

  -- Check if vim-dadbod-ui IntelliSense is available
  local intellisense_available = vim.fn.exists('*vim_dadbod_completion#dbui#is_available') == 1 and
                                  vim.api.nvim_call_function('vim_dadbod_completion#dbui#is_available', {}) == 1

  if intellisense_available then
    -- Use enhanced IntelliSense completions
    results = vim.api.nvim_call_function('vim_dadbod_completion#dbui#get_completions', {
      bufnr,
      input,
      line,
      cursor_col
    })
  end

  -- Fall back to standard completion if IntelliSense returns empty or is unavailable
  if not results or #results == 0 then
    results = vim.api.nvim_call_function('vim_dadbod_completion#omni', { 0, input })
  end

  if not results then
    transformed_callback({})
    return function() end
  end

  local by_word = {}
  for _, item in ipairs(results) do
    local key = item.word..item.kind
    if by_word[key] == nil then
      by_word[key] = item
    end
  end
  local items = {} ---@type table<string,lsp.CompletionItem>

  for _, item in pairs(by_word) do
    table.insert(items, {
      label = item.abbr or item.word,
      dup = 0,
      insertText = item.word,
      labelDetails = item.menu and { description = item.menu } or nil,
      documentation = item.info or '',
      kind = map_kind_to_cmp_lsp_kind[item.kind] or vim.lsp.protocol.CompletionItemKind.Text
    })
  end

  transformed_callback(items)

  return function() end
end

return M
