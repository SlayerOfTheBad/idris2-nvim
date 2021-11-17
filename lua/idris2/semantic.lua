local config = require('idris2.config')

local M = {}

function M.request()
  local text_params = vim.lsp.util.make_text_document_params()
  vim.lsp.buf_request(0, 'textDocument/semanticTokens/full', { textDocument = text_params })
end

function M.refresh(err, result, ctx, cfg)
  if config.semantic_refresh then
    M.request()
  end
  return vim.NIL
end

function M.full(err, result, ctx, cfg)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local bufnr = ctx.bufnr
  local legend = client.server_capabilities.semanticTokensProvider.legend
  local token_types = legend.tokenTypes
  local data = result.data

  local ns = vim.api.nvim_create_namespace('nvim-lsp-semantic-hl')
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local prev_line, prev_start = nil, 0
  for i = 1, #data, 5 do
    local delta_line = data[i]
    prev_line = prev_line and prev_line + delta_line or delta_line
    local delta_start = data[i + 1]
    prev_start = delta_line == 0 and prev_start + delta_start or delta_start
    local token_type = token_types[data[i + 3] + 1]

    local line = vim.api.nvim_buf_get_lines(bufnr, prev_line, prev_line + 1, false)[1]
    local byte_start = vim.str_byteindex(line, prev_start)
    local byte_end = vim.str_byteindex(line, prev_start + data[i + 2])
    vim.api.nvim_buf_add_highlight(bufnr, ns, 'LspSemantic_' .. token_type, prev_line, byte_start, byte_end)
  end
  print(vim.fn.expand('%:t') .. ' semantically highlighted')
end

function M.clear()
  local ns = vim.api.nvim_create_namespace('nvim-lsp-semantic-hl')
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

function M.start()
  if config.semantic_refresh then
    return
  end

  config.semantic_refresh = true
  M.request()
end

function M.stop()
  if not config.semantic_refresh then
    return
  end

  config.semantic_refresh = false
  M.clear()
end

return M