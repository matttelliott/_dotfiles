# Neovim

Hyperextensible Vim-based text editor.

https://neovim.io

## Special Characters (Nerd Fonts / Powerline)

The statusline uses Nerd Font glyphs from Unicode's Private Use Area (PUA). These characters require a Nerd Font to display correctly.

### Character Reference

| Glyph | Code Point | Name | Usage |
|-------|------------|------|-------|
|  | U+E0B0 | Powerline arrow right (solid) | Segment separators |
|  | U+E0B2 | Powerline arrow left (solid) | Right-side separators |
|  | U+E0A0 | Git branch symbol | Git info in statusline |
| 󰅚 | U+F015A | Error icon | Diagnostic signs |
| 󰀪 | U+F002A | Warning icon | Diagnostic signs |
| 󰋽 | U+F02FD | Info icon | Diagnostic signs |
| 󰌶 | U+F0336 | Hint icon | Diagnostic signs |

### Best Practice: Reference by Code Point

The config uses Lua's `vim.fn.nr2char()` to reference characters by code point instead of embedding raw glyphs. This is **the recommended approach**:

```lua
-- In init.lua (already implemented)
local arrow_right = vim.fn.nr2char(0xe0b0)  --
local arrow_left = vim.fn.nr2char(0xe0b2)   --
local git_branch = '\u{e0a0}'               --  (Lua unicode escape)
```

### Why This Matters

**Claude and other LLMs struggle with PUA characters because:**
1. They display identically to whitespace in many contexts
2. They render inconsistently across fonts/terminals
3. Copy/paste often corrupts them
4. They occupy unusual byte sequences in UTF-8

### Editing with Python

When adding new icons or modifying existing ones, use Python to generate the Lua code:

```python
#!/usr/bin/env python3
# Generate Lua code for Nerd Font characters

icons = {
    'arrow_right': 0xE0B0,
    'arrow_left': 0xE0B2,
    'git_branch': 0xE0A0,
    'error': 0xF015A,
    'warn': 0xF002A,
    'info': 0xF02FD,
    'hint': 0xF0336,
}

# Generate vim.fn.nr2char() calls
for name, code in icons.items():
    print(f"local {name} = vim.fn.nr2char(0x{code:x})  -- {chr(code)}")

# Or generate Lua unicode escapes
for name, code in icons.items():
    print(f"local {name} = '\\u{{{code:x}}}'  -- {chr(code)}")
```

### Finding Code Points

To discover the code point of an existing character:
```python
char = ""  # Paste the character here
print(f"0x{ord(char):x}")  # For vim.fn.nr2char()
print(f"\\u{{{ord(char):x}}}")  # For Lua string escape
```
