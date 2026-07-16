return {
  "nickjvandyke/opencode.nvim",
  version = "*",
  event = "VeryLazy",
  keys = {
    -- Reverts directly back to executing the native plugin functions
    {
      "<leader>oa",
      function()
        require("opencode").ask()
      end,
      desc = "OpenCode Ask",
      mode = { "n", "v" },
    },
    {
      "<leader>op",
      function()
        require("opencode").prompt()
      end,
      desc = "OpenCode Prompt",
      mode = { "n", "v" },
    },
  },
}
