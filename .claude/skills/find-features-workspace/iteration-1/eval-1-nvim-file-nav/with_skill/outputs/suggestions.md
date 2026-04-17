# Suggestions for: jump to recently-edited files in nvim without leaving home row

Your intent, paraphrased: replace the annoying `:e` + tab-completion dance with a home-row-only path to recently-edited files in nvim.

Good news: your current nvim config (`tools/neovim/nvim/init.lua`) already has telescope installed, with `<leader>s.` bound to `telescope.builtin.oldfiles` and `<leader><leader>` bound to `telescope.builtin.buffers`. So the cheapest wins are in the "existing" bucket. Here are six options in three buckets, ordered from lowest-cost to most-ambitious.

---

## Already installed (lowest cost — just use them)

### 1. `<leader>s.` opens telescope oldfiles (recent files)
Your `init.lua` binds this to `telescope.builtin.oldfiles`. That picker is exactly "files I've recently edited" with fuzzy filtering. Caveat: the `.` key is technically off the home row, so it's close to your goal but not perfect.

### 2. `<leader><leader>` opens the buffer picker
Already bound to `telescope.builtin.buffers`. For files you've touched this nvim session, two taps of the space bar gets you a fuzzy buffer list — fully home-row. Complements oldfiles (which covers files from past sessions).

---

## Addon to an existing tool (small changes to `tools/neovim/`)

### 3. Add a home-row binding `<leader>j` for telescope oldfiles (no new plugin)
A one-line add in `tools/neovim/nvim/lua/custom/plugins/keymaps.lua` to bind `<leader>j` → `Telescope oldfiles`. Space + `j` is about as home-row as it gets, and you reuse the telescope you already have. Zero new dependencies.

### 4. Add `harpoon.nvim` for pinned quick-jump between the 2-5 files you're actively editing
[ThePrimeagen/harpoon v2](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) lets you "mark" files and jump between them with `<leader>h/j/k/l` (or 1/2/3/4). When you're bouncing between the same handful of files, this is dramatically faster than oldfiles because there's no picker to filter — it's a direct jump. Pairs with telescope, doesn't replace it. Pure home-row bindings.

### 5. Add `telescope-frecency.nvim` for frequency+recency-ranked picker
[nvim-telescope/telescope-frecency.nvim](https://github.com/nvim-telescope/telescope-frecency.nvim) is a telescope extension that ranks files by **both** how recently and how often you've edited them. Your current oldfiles is pure recency — a file you touch daily but not in the last 5 minutes falls below one you opened once yesterday. Frecency fixes that. Slots into your existing telescope setup with minimal config.

---

## Brand-new tool (larger change — new `tools/<name>/`)

### 6. Install `zoxide` + `telescope-zoxide` for "jump to recent project directory, then fuzzy-find"
[ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide) is `cd` that learns — `z <fragment>` jumps to the best-matching recent directory. With [jvgrootveld/telescope-zoxide](https://github.com/jvgrootveld/telescope-zoxide) you get the same thing inside nvim via a picker. Different angle on the problem: if "recent files" for you often means "recent **project**," this nails it. Home-row bindings, zero `:e` needed.

---

## Recommendation

If you want immediate relief, #1/#2/#3 get you there with zero installs — #3 is the trivial config tweak that most directly answers your complaint. If you routinely bounce between the same handful of files, #4 (harpoon) is the crowd favourite and well worth a day's trial. #5 is a nice upgrade on top of #3. #6 is more ambitious and helps a related-but-different workflow.

Which would you like to try? You can pick any subset in any order. (I'd suggest trying #3 first — it's ~30 seconds of config and demonstrates the core answer — then add #4 on top if the problem is really "I'm juggling 3 files.")
