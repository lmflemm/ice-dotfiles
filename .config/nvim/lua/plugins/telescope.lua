return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files Telescope" },
    },
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        config = function()
          require("telescope").load_extension("fzf")
        end,
      },
    },
    opts = {
      defaults = {
        file_ignore_patterns = {
          -- Lua patterns, not shell globs
          "%.git/",
          "node_modules/",
          "dist/",
          "build/",
          "target/",
          "coverage/",
          "%.lock$",
        },
      },

      pickers = {
        find_files = {
          -- Uses ripgrep to find files.
          -- -L follows symlinks, which you already had.
          find_command = {
            "rg",
            "--files",
            "--color=never",
            "-L",

            -- Excluded folders/files
            "--glob",
            "!**/.git/**",
            "--glob",
            "!**/node_modules/**",
            "--glob",
            "!**/dist/**",
            "--glob",
            "!**/build/**",
            "--glob",
            "!**/target/**",
            "--glob",
            "!**/coverage/**",
            "--glob",
            "!**/*.lock",
          },
        },

        live_grep = {
          additional_args = function()
            return {
              "--glob",
              "!**/.git/**",
              "--glob",
              "!**/node_modules/**",
              "--glob",
              "!**/dist/**",
              "--glob",
              "!**/build/**",
              "--glob",
              "!**/target/**",
              "--glob",
              "!**/coverage/**",
              "--glob",
              "!**/*.lock",
            }
          end,
        },
      },
    },
  },

  {
    "nvim-telescope/telescope-symbols.nvim",
  },
}
