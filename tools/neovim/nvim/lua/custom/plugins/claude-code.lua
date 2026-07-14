-- Claude Code one-shot code actions in Neovim.
--
--   <leader>ai : implement the function under the cursor from its comment/signature
--   <leader>ac : update the comment/docstring under the cursor to match the code
--
-- Each keymap saves the buffer, then runs the matching script in ~/.claude/scripts/
-- with `file:line:col` of the cursor. Those scripts invoke `claude` with a tight
-- allow-list (the agent may read any file in the repo but may only edit THIS file),
-- then the buffer is reloaded to show the edit. Runs async; nvim never blocks.
--
-- Scripts require Python >=3.10, so they run under `uv` (system python may be older).

local scripts_dir = vim.fn.expand '~/.claude/scripts'

-- Model per action. opus = best, sonnet = balanced, haiku = fastest.
-- Each `claude` run is a cold start (~15s of process + repo/tool init) that
-- dominates latency; the model only trades a few seconds on top. sonnet is
-- accurate for single-function work and ~40% faster than opus.
local models = {
  implement = 'sonnet',
  comment = 'haiku',
}

---@param script string   filename in scripts_dir
---@param label string    short verb for notifications
---@param envvar string   env var the script reads to pick its model
---@param model string    model alias to pass through envvar
local function run(script, label, envvar, model)
  local uv_bin = vim.fn.exepath 'uv'
  if uv_bin == '' then
    vim.notify('claude-code: `uv` not found on PATH', vim.log.levels.ERROR)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    vim.notify('claude-code: current buffer has no file', vim.log.levels.WARN)
    return
  end

  -- Persist current contents so the script sees them on disk.
  vim.cmd 'silent noautocmd write'

  local pos = vim.api.nvim_win_get_cursor(0)
  local loc = string.format('%s:%d:%d', file, pos[1], pos[2] + 1)
  local script_path = scripts_dir .. '/' .. script
  local short = vim.fn.fnamemodify(file, ':t')

  -- Live feedback: the script blocks in one `claude` call and can't stream its
  -- internal steps, so we animate a spinner + elapsed-seconds counter on the
  -- cmdline (nvim_echo with history=false overwrites in place) until it returns.
  -- ASCII frames only — no Nerd Font glyphs (they corrupt in this repo).
  local frames = { '|', '/', '-', '\\' }
  local start = vim.uv.hrtime()
  local i = 0
  local timer = vim.uv.new_timer()
  local function stop_spinner()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    timer = nil
  end
  timer:start(0, 100, function()
    i = i + 1
    local secs = (vim.uv.hrtime() - start) / 1e9
    local msg = string.format('%s claude-code: %s (%s) @ %s:%d — %.0fs', frames[(i % #frames) + 1], label, model, short, pos[1], secs)
    vim.schedule(function()
      if timer then vim.api.nvim_echo({ { msg, 'MoreMsg' } }, false, {}) end
    end)
  end)

  vim.system(
    { uv_bin, 'run', '--python', '3.12', script_path, loc },
    { text = true, env = { [envvar] = model } },
    vim.schedule_wrap(function(res)
      stop_spinner()
      local secs = (vim.uv.hrtime() - start) / 1e9
      if res.code ~= 0 then
        local tail = (res.stderr or ''):sub(-600)
        vim.notify(string.format('claude-code: %s failed (exit %d, %.0fs)\n%s', label, res.code, secs, tail), vim.log.levels.ERROR)
        return
      end
      -- Reload the buffer to pick up the agent's on-disk edit. `:edit!` keeps
      -- undo history for files under 'undoreload' lines (default 10000), so `u`
      -- reverts the AI change.
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_call(bufnr, function() vim.cmd 'silent! edit!' end)
      end
      local ok, changes = pcall(vim.json.decode, res.stdout or '')
      local n = (ok and type(changes) == 'table') and #changes or 0
      vim.api.nvim_echo({ { '', 'None' } }, false, {}) -- clear the spinner line
      if n == 0 then
        vim.notify(string.format('claude-code: %s — no changes made (%.0fs)', label, secs), vim.log.levels.WARN)
      else
        vim.notify(string.format('claude-code: %s — applied %d change(s) in %.0fs', label, n, secs), vim.log.levels.INFO)
      end
    end)
  )
end

-- Set the keymaps at import time. This file is pulled in by lazy's
-- `{ import = 'custom.plugins' }`, which runs after init.lua sets mapleader, so
-- <leader> resolves correctly. We define the maps directly (rather than via a
-- local dir-plugin spec) because lazy identifies local plugins by their `dir`,
-- and the existing custom-keymaps spec already owns `~/.config/nvim`. Returning
-- an empty spec adds no plugin.
vim.keymap.set('n', '<leader>ai', function() run('implement_function.py', 'implement', 'IMPLEMENT_FUNCTION_MODEL', models.implement) end,
  { desc = 'Claude: [a]i [i]mplement function under cursor' })
vim.keymap.set('n', '<leader>ac', function() run('update_comment.py', 'update [c]omment under cursor', 'UPDATE_COMMENT_MODEL', models.comment) end,
  { desc = 'Claude: [a]i update [c]omment under cursor' })

return {}
