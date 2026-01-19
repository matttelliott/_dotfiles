-- nvim-highlight-colors - Color preview in code
return {
  'brenoprata10/nvim-highlight-colors',
  event = 'BufReadPost',
  opts = {
    render = 'background',
    enable_named_colors = true,
    enable_tailwind = true,
  },
}
