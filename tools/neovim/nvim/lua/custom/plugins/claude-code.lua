-- Claude Code one-shot code actions in Neovim.
--
--   <leader>ai : implement the function under the cursor from its comment/signature
--   <leader>ac : update the comment/docstring under the cursor to match the code
--   <leader>aq : cancel the running job on the current buffer
--   :ClaudeCancel   cancel the job on the current buffer
--   :ClaudeCancel!  cancel every running job
--
-- Each action saves the buffer, then runs the matching script in ~/.claude/scripts/
-- with `file:line:col` of the cursor. Those scripts invoke `claude` with a tight
-- allow-list (the agent may read any file in the repo but may only edit THIS file),
-- then the buffer is reloaded to show the edit. Runs async; nvim never blocks.
--
-- Jobs are tracked per buffer: at most one runs on a given buffer (a second
-- request is refused), but different buffers run concurrently, and a shared
-- spinner shows every job in flight. Scripts require Python >=3.10, so they run
-- under `uv` (system python may be older).

local scripts_dir = vim.fn.expand '~/.claude/scripts'

-- Model per action. opus = best, sonnet = balanced, haiku = fastest.
-- Each `claude` run is a cold start (~15s of process + repo/tool init) that
-- dominates latency; the model only trades a few seconds on top. sonnet is
-- accurate for single-function work and ~40% faster than opus.
local models = {
  implement = 'sonnet',
  comment = 'haiku',
}

-- Registry of in-flight jobs, keyed by bufnr. Each entry holds the vim.system
-- handle (for cancellation), start time, and display fields for the spinner.
local active = {}

local function job_count()
  local n = 0
  for _ in pairs(active) do n = n + 1 end
  return n
end

-- Shared cmdline spinner: one ticker renders every active job on a single line
-- (nvim_echo with history=false overwrites in place), so concurrent jobs don't
-- fight over the message area. ASCII frames only — no Nerd Font glyphs (they
-- corrupt in this repo).
local frames = { '|', '/', '-', '\\' }
local frame = 0
local ticker = nil

local function render()
  frame = frame + 1
  local spin = frames[(frame % #frames) + 1]
  local parts = {}
  for _, j in pairs(active) do
    local secs = (vim.uv.hrtime() - j.start) / 1e9
    parts[#parts + 1] = string.format('%s %s:%d %.0fs', j.label, j.short, j.line, secs)
  end
  local msg = string.format('%s claude-code: %d running — %s', spin, #parts, table.concat(parts, ', '))
  vim.schedule(function()
    if next(active) then vim.api.nvim_echo({ { msg, 'MoreMsg' } }, false, {}) end
  end)
end

local function start_ticker()
  if ticker then return end
  ticker = vim.uv.new_timer()
  ticker:start(0, 120, render)
end

local function stop_ticker_if_idle()
  if next(active) == nil and ticker then
    ticker:stop()
    ticker:close()
    ticker = nil
    vim.schedule(function() vim.api.nvim_echo({ { '', 'None' } }, false, {}) end) -- clear the line
  end
end

---Cancel the job on `bufnr`. Returns true if one was running.
local function cancel(bufnr)
  local job = active[bufnr]
  if not job then return false end
  job.cancelled = true
  local obj = job.obj
  if obj and obj.pid then
    -- Kill the whole process group (uv -> python -> claude). Killing only uv
    -- orphans claude, which would keep running and still edit the file. The job
    -- is spawned detached (new session/group leader), so signalling -pid hits
    -- the group. Fall back to killing just the handle if the group kill fails.
    local ok = pcall(vim.uv.kill, -obj.pid, 'sigterm')
    if not ok then pcall(function() obj:kill 'sigterm' end) end
  elseif obj then
    obj:kill 'sigterm'
  end
  return true
end

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

  -- One job per buffer: refuse a second so two runs can't race the same file.
  if active[bufnr] then
    vim.notify('claude-code: a job is already running on this buffer (<leader>aq to cancel)', vim.log.levels.WARN)
    return
  end

  -- Persist current contents so the script sees them on disk.
  vim.cmd 'silent noautocmd write'

  local pos = vim.api.nvim_win_get_cursor(0)
  local loc = string.format('%s:%d:%d', file, pos[1], pos[2] + 1)
  local short = vim.fn.fnamemodify(file, ':t')

  local job = { start = vim.uv.hrtime(), label = label, short = short, line = pos[1], cancelled = false }
  active[bufnr] = job
  start_ticker()

  job.obj = vim.system(
    { uv_bin, 'run', '--python', '3.12', scripts_dir .. '/' .. script, loc },
    -- detach = new session/group leader so cancel can group-kill the whole tree.
    { text = true, env = { [envvar] = model }, detach = true },
    vim.schedule_wrap(function(res)
      active[bufnr] = nil
      stop_ticker_if_idle()
      local secs = (vim.uv.hrtime() - job.start) / 1e9

      if job.cancelled then
        vim.notify(string.format('claude-code: %s cancelled after %.0fs (%s)', label, secs, short), vim.log.levels.WARN)
        return
      end
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
vim.keymap.set('n', '<leader>aq', function()
  if not cancel(vim.api.nvim_get_current_buf()) then
    vim.notify('claude-code: no running job on this buffer', vim.log.levels.INFO)
  end
end, { desc = 'Claude: [a]i cancel/[q]uit job on current buffer' })

vim.api.nvim_create_user_command('ClaudeCancel', function(o)
  if o.bang then
    local n = job_count()
    for b in pairs(active) do cancel(b) end
    vim.notify(string.format('claude-code: cancelling %d job(s)', n), vim.log.levels.INFO)
  elseif not cancel(vim.api.nvim_get_current_buf()) then
    vim.notify('claude-code: no running job on this buffer', vim.log.levels.INFO)
  end
end, { bang = true, desc = 'Cancel the Claude job on the current buffer (! = all jobs)' })

return {}
