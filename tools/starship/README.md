# starship

Minimal, fast, and customizable prompt for any shell.

https://starship.rs/

## Special Characters (Nerd Fonts / Powerline)

The prompt uses Nerd Font glyphs from Unicode's Private Use Area (PUA). These characters require a Nerd Font to display correctly.

### Character Reference

| Glyph | Code Point | Name | Usage |
|-------|------------|------|-------|
|  | U+E0B0 | Powerline arrow right (solid) | Segment separators |
|  | U+F007 | User icon | Username module |
|  | U+F108 | Computer/desktop icon | Hostname module |
|  | U+F07B | Folder icon | Directory module |
|  | U+E0A0 | Git branch symbol | Git branch module |
| 󰜎 | U+F070E | Running jobs icon | Jobs module |
|  | U+F061 | Arrow right | Success prompt symbol |
|  | U+F061 | Arrow right | Error prompt symbol |

### Editing These Characters

**Claude and other LLMs struggle with PUA characters because they display identically to whitespace or render inconsistently.** Use Python to edit these files safely:

```python
#!/usr/bin/env python3
# Edit starship special characters by code point

POWERLINE_RIGHT = chr(0xE0B0)   #
GIT_BRANCH = chr(0xE0A0)        #
USER_ICON = chr(0xF007)         #
COMPUTER = chr(0xF108)          #
FOLDER = chr(0xF07B)            #
ARROW = chr(0xF061)             #
JOBS = chr(0x1F70E)             # 󰜎 (note: 6-digit code point)

# Example: Generate a format string
username_format = f"[ {USER_ICON} $user ]($style)[{POWERLINE_RIGHT}](fg:#7aa2f7 bg:#3b4261)"
print(username_format)
```

To find/replace characters:
```python
with open('starship.toml', 'r') as f:
    content = f.read()

# Replace by code point
old_icon = chr(0xE0A0)
new_icon = chr(0xF126)  # Different git icon
content = content.replace(old_icon, new_icon)

with open('starship.toml', 'w') as f:
    f.write(content)
```

### Finding Code Points

To discover the code point of an existing character:
```python
char = ""  # Paste the character here
print(f"U+{ord(char):04X}")  # Prints: U+E0B0
```
