return {
  -- tokyonight-night instead of LazyVim's default moon
  { "folke/tokyonight.nvim", opts = { style = "night" } },

  -- explorer: show hidden + gitignored files by default (H / I still toggle)
  {
    "folke/snacks.nvim",
    opts = { picker = { sources = { explorer = { hidden = true, ignored = true } } } },
  },
}
