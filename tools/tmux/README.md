# tmux

Terminal multiplexer for managing multiple terminal sessions.

https://github.com/tmux/tmux

## Special Characters (Nerd Fonts / Powerline)

The statusline uses Nerd Font glyphs from Unicode's Private Use Area (PUA). These characters require a Nerd Font to display correctly.

### Character Reference

| Glyph | Code Point | Name | Usage |
|-------|------------|------|-------|
|  | U+E0B0 | Powerline arrow right (solid) | Segment separators |
|  | U+E0B2 | Powerline arrow left (solid) | Right-side separators |
|  | U+F015 | House icon | Hostname indicator |
|  | U+EB9D | Terminal/session icon | Session name |
|  | U+F073 | Calendar icon | Date display |
|  | U+F240 | Battery icon | Battery status |

### Editing These Characters

**Claude and other LLMs struggle with PUA characters because they display identically to whitespace or render inconsistently.** Use Python to edit these files safely:

```python
#!/usr/bin/env python3
# Edit tmux special characters by code point

POWERLINE_RIGHT = chr(0xE0B0)  #
POWERLINE_LEFT = chr(0xE0B2)   #
HOUSE = chr(0xF015)            #
TERMINAL = chr(0xEB9D)         #
CALENDAR = chr(0xF073)         #
BATTERY = chr(0xF240)          #

# Example: Generate a status-left string
status_left = f"#[fg=#1a1b26,bg=#7aa2f7,bold] {HOUSE} #h #[fg=#7aa2f7,bg=#3b4261]{POWERLINE_RIGHT}"
print(status_left)
```

To find/replace characters:
```python
with open('tmux.conf.j2', 'r') as f:
    content = f.read()

# Replace by code point
content = content.replace(chr(0xE0B0), chr(0xE0B1))  # Solid to outline arrow

with open('tmux.conf.j2', 'w') as f:
    f.write(content)
```
