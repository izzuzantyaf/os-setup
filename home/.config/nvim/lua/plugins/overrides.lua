return {
  -- tokyonight-night instead of LazyVim's default moon
  { "folke/tokyonight.nvim", opts = { style = "night" } },

  -- inline git blame ("You, 3 days ago • abc1234")
  {
    "gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
    },
  },

  -- pickers/explorer: include hidden + gitignored by default (alt-h / alt-i still toggle)
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = { hidden = true, ignored = true },
          files = { hidden = true, ignored = true },
          grep = { hidden = true, ignored = true },
        },
      },
      image = { enabled = true },
    },
  },
}
