return {
  -- 1. Load the gruvbox colorscheme naturally
  { "wittyjudge/gruvbox-material.nvim" },

  -- 2. Direct LazyVim to prioritize your theme
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox-material",
    },
  },

  -- 3. Block modern which-key v3+ and force true terminal colors
  {
    "folke/which-key.nvim",
    config = function(_, opts)
      -- Force true 24-bit color support right before setting highlights
      vim.opt.termguicolors = true

      -- Standard LazyVim initialization loop
      require("which-key").setup(opts)

      -- Execute a global UI hook to catch the actual rendering pipeline
      vim.api.nvim_create_autocmd("UIEnter", {
        callback = function()
          -- Use explicitly clear fallback styles
          vim.cmd([[
            highlight! clear WhichKey
            highlight! clear WhichKeyDesc
            highlight! clear WhichKeyGroup

            " Target modern v3+ tokens and explicitly pass standard ANSI names
            highlight! WhichKeyNormal ctermfg=black ctermbg=magenta guifg=black guibg=magenta
            highlight! WhichKeyTitle ctermfg=black ctermbg=magenta guifg=black guibg=magenta
            highlight! WhichKeyIcon ctermfg=black ctermbg=magenta guifg=black guibg=magenta
            highlight! WhichKeySeparator ctermfg=black ctermbg=magenta guifg=black guibg=magenta
          ]])
        end,
      })
    end,
  }
}

